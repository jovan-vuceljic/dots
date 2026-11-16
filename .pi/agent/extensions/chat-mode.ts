/**
 * Chat mode — `/chat [on|off]`, Alt+C, `--chat`.
 *
 * For asking questions rather than handing over a task. It sits next to plan-mode but is
 * deliberately not part of that vendored fork, and it is the lighter of the two:
 *
 *   plan mode   removes edit/write, runs allowlisted read-only bash freely and asks before
 *               any other command, and steers the model into a numbered "Plan:" that it
 *               then offers to execute.
 *   chat mode   steers the model into just answering (no plan, no implementing) and puts
 *               every bash command and every edit/write behind a Yes/No prompt. read, grep,
 *               find and ls stay free, so a question about the code costs no clicks.
 *
 * The instructions go in through `before_agent_start`'s systemPrompt, which is rebuilt every
 * turn, rather than as an injected message the way plan-mode does it. Nothing is stored in
 * the session, so there is no stale "[CHAT MODE]" text to filter out after leaving and nothing
 * piles up in the 24k windows. The price: a toggle changes the system prompt (and the tool
 * list), so the first reply after one re-prefills the whole context on llama.cpp.
 *
 * Tools: grep/find/ls are *added* on entry, and only the ones this added are removed on exit,
 * never a snapshot restore. That composes with plan-mode's own snapshot/restore in any toggle
 * order without ever re-enabling edit/write behind plan mode's back.
 *
 * Plan mode wins. Chat mode won't switch on while plan mode is on, and goes quiet (no prompt
 * text, no gate) if plan mode is switched on later. Plan state is read from plan-mode's own
 * `plan-mode` session entries, because `pi.getFlag` only sees an extension's own flags, so a
 * session started with `--plan` and never toggled reads as "off".
 *
 * A dangerous command in chat mode is asked about twice: here and in permission-gate.ts, in
 * whichever order pi loaded the two. A No to either stops it.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

// Read-only tools switched on for the mode, so the model can look things up without a prompt.
const READ_TOOLS = ["grep", "find", "ls"];

// Tools that only run after a Yes. Everything else (read, grep, questionnaire, …) is free.
const GATED_TOOLS = new Set(["bash", "edit", "write"]);

const DECLINED =
	"The user declined this in chat mode. Do not retry it; answer from what you already have, or ask the user.";

const CHAT_PROMPT = `[CHAT MODE]
The user wants to ask questions and talk things through, not hand you a task.
- Answer the question directly and concisely.
- Do not write a plan or a list of steps to carry out, and do not start implementing anything.
- Read files (read, grep, find, ls) when the answer depends on the actual code or config.
- Every bash command and every file edit needs the user's approval. Use bash only when the answer needs it, and say in one line what you will run and why before calling it.
- If the user declines a tool call, do not retry it.
- If the question is ambiguous, ask a short clarifying question instead of guessing.`;

interface ChatModeState {
	enabled: boolean;
}

type CustomEntry = { type: string; customType?: string; data?: unknown };

function lastEntry<T>(ctx: ExtensionContext, customType: string): T | undefined {
	const entry = (ctx.sessionManager.getEntries() as CustomEntry[])
		.filter((e) => e.type === "custom" && e.customType === customType)
		.pop();
	return entry?.data as T | undefined;
}

function planModeOn(ctx: ExtensionContext): boolean {
	return lastEntry<{ enabled?: boolean }>(ctx, "plan-mode")?.enabled === true;
}

export default function chatModeExtension(pi: ExtensionAPI): void {
	let enabled = false;
	// The READ_TOOLS this extension switched on, i.e. the only ones it may switch off again.
	let addedTools: string[] = [];

	pi.registerFlag("chat", {
		description: "Start in chat mode (answers only; bash and edits ask first)",
		type: "boolean",
		default: false,
	});

	function addReadTools(): void {
		const active = pi.getActiveTools();
		addedTools = READ_TOOLS.filter((name) => !active.includes(name));
		if (addedTools.length > 0) pi.setActiveTools([...active, ...addedTools]);
	}

	function removeReadTools(ctx: ExtensionContext): void {
		// Leaving while plan mode is on: plan mode owns the tool list now, and it wants these.
		if (addedTools.length > 0 && !planModeOn(ctx)) {
			const added = new Set(addedTools);
			pi.setActiveTools(pi.getActiveTools().filter((name) => !added.has(name)));
		}
		addedTools = [];
	}

	function updateStatus(ctx: ExtensionContext): void {
		ctx.ui.setStatus("chat-mode", enabled ? ctx.ui.theme.fg("accent", "💬 chat") : undefined);
	}

	function setChatMode(on: boolean, ctx: ExtensionContext): void {
		if (on === enabled) {
			ctx.ui.notify(`Chat mode is already ${on ? "on" : "off"}.`);
			return;
		}
		if (on && planModeOn(ctx)) {
			ctx.ui.notify("Plan mode is on. Leave it first (Shift+Tab or /plan).", "warning");
			return;
		}

		enabled = on;
		if (enabled) {
			addReadTools();
			ctx.ui.notify("Chat mode on: answers only, bash and edits ask first.");
		} else {
			removeReadTools(ctx);
			ctx.ui.notify("Chat mode off.");
		}
		updateStatus(ctx);
		pi.appendEntry("chat-mode", { enabled } satisfies ChatModeState);
	}

	pi.registerCommand("chat", {
		description: "Toggle chat mode: answers only, bash and edits ask first (usage: /chat [on|off])",
		handler: async (args, ctx) => {
			const raw = args.trim().toLowerCase();
			if (raw && raw !== "on" && raw !== "off") {
				ctx.ui.notify("usage: /chat [on|off]", "error");
				return;
			}
			setChatMode(raw ? raw === "on" : !enabled, ctx);
		},
	});

	pi.registerShortcut("alt+c", {
		description: "Toggle chat mode",
		handler: async (ctx) => setChatMode(!enabled, ctx),
	});

	pi.on("tool_call", async (event, ctx) => {
		if (!enabled || !GATED_TOOLS.has(event.toolName) || planModeOn(ctx)) return undefined;

		if (!ctx.hasUI) {
			// Non-interactive (`pi -p --chat`): nothing can approve, so refuse.
			return { block: true, reason: "Chat mode: blocked (no UI to approve it)" };
		}

		const what =
			event.toolName === "bash"
				? `run this command?\n\n  ${event.input.command as string}`
				: `${event.toolName} ${event.input.path as string}?`;
		const choice = await ctx.ui.select(`💬 Chat mode: ${what}\n\nAllow?`, ["Yes", "No"]);

		if (choice !== "Yes") {
			return { block: true, reason: DECLINED };
		}
		return undefined;
	});

	pi.on("before_agent_start", async (event, ctx) => {
		if (!enabled || planModeOn(ctx)) return undefined;
		return { systemPrompt: `${event.systemPrompt}\n\n${CHAT_PROMPT}` };
	});

	// Restore on start/resume. Each session gets a fresh instance, so this starts from scratch.
	pi.on("session_start", async (_event, ctx) => {
		enabled = lastEntry<ChatModeState>(ctx, "chat-mode")?.enabled ?? pi.getFlag("chat") === true;
		if (enabled) addReadTools();
		updateStatus(ctx);
	});
}
