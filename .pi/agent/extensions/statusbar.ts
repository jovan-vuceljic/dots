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
 *   ↑ ↓ tokens  session input / output tokens         (Claude 💰)  plain arrows
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

// Decode throughput (tokens/sec) of the most recent assistant response, measured
// from the first streamed token to message end so prompt-eval time is excluded.
let lastTps = 0;
let genFirstTokenAt = 0;
let sawToken = false;

// Set from inside the footer factory so events can trigger a re-render.
let requestRender: (() => void) | undefined;

function collapseHome(p: string): string {
	const home = process.env.HOME || "";
	if (p === home) return "~";
	if (home && p.startsWith(`${home}/`)) return `~${p.slice(home.length)}`;
	return p;
}

function fmtTokens(n: number): string {
	return n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`;
}

/** Cumulative session tokens, plus the last request's input tokens (~ current
 *  context-window fill). */
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
			input += usage.input;
			output += usage.output;
			lastInput = usage.input;
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
		const secs = genFirstTokenAt ? (Date.now() - genFirstTokenAt) / 1000 : 0;
		if (secs > 0 && output > 0) lastTps = output / secs;
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

					// 󰓅  tokens/sec of the last response
					if (lastTps > 0) {
						parts.push(
							theme.fg("accent", ICON.tps) + " " + theme.fg("text", lastTps.toFixed(1)) + theme.fg("dim", " t/s"),
						);
					}

					// ↑ ↓  cumulative session tokens (Claude's 💰 slot; local models are $0)
					if (input || output) {
						parts.push(theme.fg("dim", `${ICON.up}${fmtTokens(input)} ${ICON.down}${fmtTokens(output)}`));
					}

					return [truncateToWidth(parts.join(sep), width)];
				},
			};
		});
	};

	pi.on("session_start", async (_event, ctx) => {
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
