/**
 * Pi status bar (custom footer)
 *
 * Replaces pi's default footer via `ctx.ui.setFooter()`. It mirrors the layout
 * and *meaning* of the Claude Code status line (`~/.config/claude/statusline.py`),
 * but swaps the emoji for Nerd Font glyphs — the same Material Design set already
 * used across tmux (waybar cpu/mem/net glyphs) and nvim — so it reads natively in
 * kitty (CaskaydiaCove Nerd Font Mono). Colors come from the active pi theme
 * (catppuccin-mocha), not hard-coded ANSI.
 *
 * Segments render left → right and truncate at the terminal edge, so the most
 * useful info stays visible on a narrow pane. Each icon echoes the Claude emoji
 * it replaces:
 *
 *   󰉋  dir      cwd, ~-collapsed                      (Claude 📁)  U+F024B nf-md-folder
 *   󰘬  git      current branch (only inside a repo)   (Claude 🌿)  U+F062C nf-md-source_branch
 *   󰚩  model    model id + · thinking level           (Claude 🤖)  U+F06A9 nf-md-robot
 *   󰈚  context  % of context window used (+ tokens)   (Claude 📝)  U+F021A nf-md-text_box
 *   󰓅  t/s      last response's decode throughput                 U+F04C5 nf-md-speedometer
 *               (llama.cpp's own server-side number + dim ` pp N` prompt-processing
 *               speed when the final SSE chunk carries `timings`; otherwise the
 *               client-side clock -- see "server-side timings" below)
 *   ↑ ↓ tokens  session prompt / output tokens        (Claude 🔢)  plain arrows
 *               (prompt = input + cache read + cache write: everything the server
 *               processed, matching the Claude bar — llama.cpp reports a cached
 *               prefix as cacheRead, so bare usage.input is a few dozen tokens)
 *
 * git, context, t/s and tokens only appear once there is data for them (i.e. after
 * the first response, and git only inside a git repo). Extension statuses (e.g.
 * plan-mode's "⏸ plan") are preserved at the far left. The Claude bar's system row
 * (RAM/CPU/temp/disk) is intentionally omitted — that data isn't in the footer API,
 * and the tmux bar below pi already shows cpu/mem/net.
 *
 * Two extras beyond the footer line:
 *   - a themed pulse working-indicator (the spinner shown while pi streams), and
 *   - a 󰀪 context-budget warning widget above the editor once the window passes
 *     80% full, nudging a /compact before things get truncated.
 *
 * Restore the built-in footer (and reset the indicator/widget) with `/statusbar`.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

// Nerd Font (Material Design) glyphs — verified to render in the user's font.
const ICON = {
	dir: "\u{F024B}", // 󰉋 nf-md-folder
	git: "\u{F062C}", // 󰘬 nf-md-source_branch
	model: "\u{F06A9}", // 󰚩 nf-md-robot
	context: "\u{F021A}", // 󰈚 nf-md-text_box
	tps: "\u{F04C5}", // 󰓅 nf-md-speedometer
	warn: "\u{F002A}", // 󰀪 nf-md-alert_outline (same glyph nvim uses for warnings)
	up: "↑", // ↑
	down: "↓", // ↓
};

// Widget key for the context-budget warning shown above the editor.
const CTX_WIDGET = "statusbar-context-warning";
// Show the warning once the context window is this full (%).
const CTX_WARN_AT = 80;

// Current thinking level, tracked via thinking_level_select (footer render has no
// direct access to it). Defaults to the settings.json default of "off".
let thinkingLevel = "off";

// Decode throughput (tokens/sec) of the most recent assistant response. Preferred
// source: the server's own timings (below). Fallback: a client-side clock from the
// first streamed token to message end, so prompt-eval time is excluded.
let lastTps = 0;
let lastPp = 0; // prompt-processing t/s, server-side only (0 = unknown)
let genFirstTokenAt = 0;
let sawToken = false;

// --- server-side timings (llama.cpp) ----------------------------------------
// llama.cpp puts a `timings` object on the final SSE chunk (the one carrying `usage`):
// prompt_n / prompt_ms / prompt_per_second, predicted_n / predicted_ms /
// predicted_per_second, cache_n, draft_n / draft_n_accepted. pi-ai's openai-completions
// provider reads only `usage` and drops the rest, and the extension API has no HTTP
// hook, so the one way to see it is to wrap globalThis.fetch and tee the SSE body.
// That is sanctioned: pi's http-dispatcher installs undici's fetch at startup and
// deliberately keeps a later override ("If a caller replaced fetch after module load,
// preserve that deliberate override"), and pi-ai builds `new OpenAI({ fetch: undefined })`
// per request, which falls back to globalThis.fetch -- so a wrapper installed at
// session_start sees every chat completion. Only POST */chat/completions responses
// with a text/event-stream body are teed; other providers' streams carry no `timings`
// and are passed through untouched apart from the tee. The tap stays installed for the
// life of the process (`/statusbar` off just stops displaying it; `/reload` rebinds the
// sink instead of wrapping twice).
interface ServerTimings {
	tps: number; // predicted_per_second
	pp: number; // prompt_per_second
	predictedN: number;
	promptN: number;
	cacheN: number;
}
// Latest timings seen on the wire, consumed by message_end. Paired with the message by
// predicted_n === usage.output, so a compaction/summary call's timings never get
// attributed to the next visible response.
let pendingServerTimings: ServerTimings | undefined;

const FETCH_TAP_KEY = "__piStatusbarFetchTap";

/** Read one branch of a teed SSE body and report every `timings` object it carries. */
async function scanSse(stream: ReadableStream<Uint8Array>, onTimings: (t: ServerTimings) => void): Promise<void> {
	const reader = stream.getReader();
	const dec = new TextDecoder();
	let buf = "";
	try {
		for (;;) {
			const { value, done } = await reader.read();
			if (done) break;
			buf += dec.decode(value, { stream: true });
			let nl: number;
			while ((nl = buf.indexOf("\n")) >= 0) {
				const line = buf.slice(0, nl).trim();
				buf = buf.slice(nl + 1);
				if (!line.startsWith("data:")) continue;
				const payload = line.slice(5).trim();
				if (!payload.includes('"timings"')) continue; // cheap pre-filter: parse only the final chunk
				try {
					const t = JSON.parse(payload)?.timings;
					if (t && typeof t.predicted_per_second === "number") {
						onTimings({
							tps: t.predicted_per_second,
							pp: typeof t.prompt_per_second === "number" ? t.prompt_per_second : 0,
							predictedN: t.predicted_n ?? 0,
							promptN: t.prompt_n ?? 0,
							cacheN: t.cache_n ?? 0,
						});
					}
				} catch {
					// not JSON: ignore
				}
			}
		}
	} catch {
		// aborted / cancelled stream: the primary branch reports that, we just stop
	}
}

/** Wrap globalThis.fetch once; on /reload only rebind the sink. */
function installFetchTap(): void {
	const g = globalThis as unknown as Record<string, unknown>;
	const sink = (t: ServerTimings) => {
		pendingServerTimings = t;
	};
	const existing = g[FETCH_TAP_KEY] as { sink: (t: ServerTimings) => void } | undefined;
	if (existing) {
		existing.sink = sink;
		return;
	}
	const tap = { sink };
	g[FETCH_TAP_KEY] = tap;
	const orig = globalThis.fetch;
	globalThis.fetch = (async (input: Parameters<typeof fetch>[0], init?: Parameters<typeof fetch>[1]) => {
		const res = await orig(input, init);
		let url = "";
		try {
			url = typeof input === "string" ? input : input instanceof URL ? input.href : ((input as Request)?.url ?? "");
		} catch {
			return res;
		}
		if (!url.endsWith("/chat/completions") || !res.body) return res;
		if (!(res.headers.get("content-type") ?? "").includes("text/event-stream")) return res;
		const [ours, theirs] = res.body.tee();
		void scanSse(ours, (t) => tap.sink(t));
		return new Response(theirs, res);
	}) as typeof fetch;
}

// Set from inside the footer factory so events can trigger a re-render.
let requestRender: (() => void) | undefined;

function collapseHome(p: string): string {
	const home = process.env.HOME || "";
	if (p === home) return "~";
	if (home && p.startsWith(`${home}/`)) return `~${p.slice(home.length)}`;
	return p;
}

/** 1234 -> 1.2k, 843000 -> 843k, 1234567 -> 1.2M (same boundaries as the Claude bar's
 *  fmt_tokens: 0.9995 / 9.95 so a value never prints as "10.0k" or "1000k"). */
function fmtTokens(n: number): string {
	for (const [unit, div] of [
		["M", 1e6],
		["k", 1e3],
	] as const) {
		const v = n / div;
		if (v < 0.9995) continue;
		return v >= 9.95 ? `${v.toFixed(0)}${unit}` : `${v.toFixed(1)}${unit}`;
	}
	return `${Math.round(n)}`;
}

/** Cumulative session tokens, plus the last request's prompt size (~ current
 *  context-window fill).
 *
 *  Prompt = input + cacheRead + cacheWrite. pi-ai splits a cached prefix out of
 *  `usage.input` (llama.cpp too: the second call of a session reports e.g. input 20,
 *  cacheRead 2417), so summing bare `input` undercounted ↑ and -- worse -- made the
 *  context % and the ≥80% warning read near zero on every cached call. */
function tokenStats(ctx: ExtensionContext): {
	input: number;
	output: number;
	lastInput: number;
} {
	let input = 0;
	let output = 0;
	let lastInput = 0;
	for (const entry of ctx.sessionManager.getBranch()) {
		if (entry.type === "message" && entry.message.role === "assistant") {
			const usage = (entry.message as AssistantMessage).usage;
			if (!usage) continue; // aborted stream: no usage — a throwing render kills the TUI
			const prompt = (usage.input ?? 0) + (usage.cacheRead ?? 0) + (usage.cacheWrite ?? 0);
			input += prompt;
			output += usage.output ?? 0;
			lastInput = prompt;
		}
	}
	return { input, output, lastInput };
}

/** Show/hide the above-editor warning when the context window is nearly full. */
function updateContextWidget(ctx: ExtensionContext): void {
	if (ctx.mode !== "tui") return;
	const contextWindow = ctx.model?.contextWindow;
	const { lastInput } = tokenStats(ctx);
	if (!contextWindow || lastInput <= 0) {
		ctx.ui.setWidget(CTX_WIDGET, undefined);
		return;
	}
	const pct = (lastInput / contextWindow) * 100;
	if (pct < CTX_WARN_AT) {
		ctx.ui.setWidget(CTX_WIDGET, undefined);
		return;
	}
	const th = ctx.ui.theme;
	const col = pct >= 90 ? "error" : "warning";
	const line =
		th.fg(col, `${ICON.warn} context ${pct.toFixed(0)}%`) +
		th.fg("dim", ` (${fmtTokens(lastInput)}/${fmtTokens(contextWindow)}) — /compact soon`);
	ctx.ui.setWidget(CTX_WIDGET, [line]);
}

/** A gentle catppuccin "breathing" pulse for the streaming working-indicator. */
function pulseIndicator(ctx: ExtensionContext) {
	const th = ctx.ui.theme;
	return {
		frames: [th.fg("dim", "·"), th.fg("muted", "•"), th.fg("accent", "●"), th.fg("muted", "•")],
		intervalMs: 120,
	};
}

export default function (pi: ExtensionAPI) {
	let enabled = true;

	pi.on("thinking_level_select", async (event) => {
		thinkingLevel = event.level;
		requestRender?.();
	});

	pi.on("model_select", async () => {
		requestRender?.();
	});

	// --- t/s timing: bracket each assistant response and clock its generation ---
	pi.on("message_start", async (event) => {
		if (event.message?.role !== "assistant") return;
		sawToken = false;
		genFirstTokenAt = 0;
	});

	pi.on("message_update", async (event) => {
		if (event.message?.role !== "assistant") return;
		if (!sawToken) {
			sawToken = true;
			genFirstTokenAt = Date.now();
		}
	});

	pi.on("message_end", async (event, ctx) => {
		if (event.message?.role !== "assistant") return;
		const output = (event.message as AssistantMessage).usage?.output ?? 0;
		// The tee reader and pi-ai consume the same final chunk; pi-ai's path to this
		// event is longer, but give the reader one macrotask in case it is still behind.
		if (!pendingServerTimings) await new Promise((r) => setTimeout(r, 20));
		const srv = pendingServerTimings;
		pendingServerTimings = undefined;
		if (srv && srv.predictedN > 0 && (output === 0 || srv.predictedN === output)) {
			lastTps = srv.tps;
			lastPp = srv.pp;
		} else {
			const secs = genFirstTokenAt ? (Date.now() - genFirstTokenAt) / 1000 : 0;
			if (secs > 0 && output > 0) lastTps = output / secs;
			lastPp = 0;
		}
		requestRender?.();
		if (enabled) updateContextWidget(ctx);
	});

	const install = (ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;
		ctx.ui.setWorkingIndicator(pulseIndicator(ctx));
		updateContextWidget(ctx);
		ctx.ui.setFooter((tui, theme, footerData) => {
			const sep = theme.fg("dim", " │ ");
			requestRender = () => tui.requestRender();
			const unsub = footerData.onBranchChange(() => tui.requestRender());
			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					const parts: string[] = [];

					// Preserve extension statuses (plan-mode "⏸ plan", etc.) up front.
					for (const status of footerData.getExtensionStatuses().values()) {
						if (status) parts.push(status);
					}

					// 󰉋  directory
					parts.push(theme.fg("accent", ICON.dir) + " " + theme.fg("text", collapseHome(ctx.cwd)));

					// 󰘬  git branch (only inside a repo)
					const branch = footerData.getGitBranch();
					if (branch) parts.push(theme.fg("accent", ICON.git) + " " + theme.fg("success", branch));

					// 󰚩  model (+ · thinking level)
					if (ctx.model?.id) {
						let model = theme.fg("accent", ICON.model) + " " + theme.fg("text", ctx.model.id);
						if (thinkingLevel && thinkingLevel !== "off") {
							model += theme.fg("dim", ` · ${thinkingLevel}`);
						}
						parts.push(model);
					}

					// 󰈚  context window usage (% when the window is known, else raw tokens)
					const { input, output, lastInput } = tokenStats(ctx);
					if (lastInput > 0) {
						const contextWindow = ctx.model?.contextWindow;
						let seg = theme.fg("accent", ICON.context) + " ";
						if (contextWindow) {
							const pct = Math.min(100, (lastInput / contextWindow) * 100);
							const col = pct < 50 ? "success" : pct < 80 ? "warning" : "error";
							seg += theme.fg(col, `${pct.toFixed(0)}%`) + theme.fg("dim", ` (${fmtTokens(lastInput)})`);
						} else {
							seg += theme.fg("text", fmtTokens(lastInput));
						}
						parts.push(seg);
					}

					// 󰓅  tokens/sec of the last response (+ dim prompt-processing t/s when the
					// server reported it)
					if (lastTps > 0) {
						let seg = theme.fg("accent", ICON.tps) + " " + theme.fg("text", lastTps.toFixed(1)) + theme.fg("dim", " t/s");
						if (lastPp > 0) seg += theme.fg("dim", ` pp ${lastPp.toFixed(0)}`);
						parts.push(seg);
					}

					// ↑ ↓  cumulative session prompt / output tokens (Claude's 🔢 segment)
					if (input || output) {
						parts.push(theme.fg("dim", `${ICON.up}${fmtTokens(input)} ${ICON.down}${fmtTokens(output)}`));
					}

					return [truncateToWidth(parts.join(sep), width)];
				},
			};
		});
	};

	pi.on("session_start", async (_event, ctx) => {
		// Installed here, not at load time: pi's http-dispatcher only swaps in undici's
		// fetch (idle timeout, proxy) while globalThis.fetch is still the original, so the
		// tap must not get there first. By session_start, startup is done.
		installFetchTap();
		if (enabled) install(ctx);
	});

	pi.registerCommand("statusbar", {
		description: "Toggle the custom pi status bar footer",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			if (enabled) {
				install(ctx);
				ctx.ui.notify("Custom status bar enabled", "info");
			} else {
				ctx.ui.setFooter(undefined);
				ctx.ui.setWorkingIndicator(); // restore pi's default spinner
				ctx.ui.setWidget(CTX_WIDGET, undefined);
				ctx.ui.notify("Default footer restored", "info");
			}
		},
	});
}
