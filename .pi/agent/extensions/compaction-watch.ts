/**
 * Compaction Watch
 *
 * Compaction is otherwise silent, which is why "compacting fails a lot" took code
 * reading and arithmetic to diagnose rather than a glance at a log. This makes it
 * visible and, for the one reason that signals trouble, says WHICH trouble.
 *
 * pi reports a `reason` on every compaction:
 *   "manual"    - you ran /compact
 *   "threshold" - the healthy path: contextTokens passed contextWindow - reserveTokens
 *   "overflow"  - recovery, not prevention: the previous assistant turn ended badly,
 *                 pi compacts and (when `willRetry`) re-runs that turn once
 *
 * Since pi 0.84.3 "overflow" covers TWO different situations, and the numbers on the
 * last assistant message tell them apart (CLAUDE.md > Compaction tuning has the
 * arithmetic for both):
 *
 *   1. A real overflow — the server rejected the prompt (stopReason "error" matching
 *      pi's overflow patterns), or reported more input than the declared window.
 *      Fix: contextWindow / reserveTokens / maxTokens are wrong for the model in use.
 *   2. Truncated-reply recovery — the reply stopped with stopReason "length" while
 *      usage.output is BELOW the model's maxTokens. The request itself carried a smaller
 *      max_tokens: before every call pi-ai clamps it to
 *      `contextWindow − its own token estimate − 4096` (clampMaxTokensToContext,
 *      CONTEXT_SAFETY_TOKENS) and then shrinks the thinking budget so that only 1024
 *      answer tokens remain. The window was never full. On a 24k window with maxTokens
 *      4096 the clamp bites at any estimate above 16384 — the same number as the
 *      compaction threshold with reserveTokens 8192 — so it hits in the gaps the threshold
 *      check never sees: the first request after a compaction (no server usage to anchor
 *      on, so the system prompt and the tool schemas join the estimate) and the first call
 *      of a user turn (the new message). Thinking models feel it first: 2048 of thinking
 *      leaves a clamped reply about 1024 tokens of answer, and a `write` payload is cut.
 *
 * The old message here blamed every "overflow" on `reserveTokens < maxTokens`, which is
 * wrong for case 2 — the one that actually shows up (Ornith, 2026-10-22). Now the
 * notification names the case and prints the numbers (output vs maxTokens, context vs
 * window, the estimate the clamp implies), so the next occurrence is diagnosable from the
 * screen instead of from a session file.
 *
 * Note there is no event for a *failed* auto-compaction — `onError` exists only on the
 * manual `ctx.compact()` call — so catching the overflow entry is the earliest reliable
 * warning available. Observe-only: it never alters the compaction itself.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** pi-ai's CONTEXT_SAFETY_TOKENS: the margin clampMaxTokensToContext keeps below the window. */
const PI_CONTEXT_SAFETY_TOKENS = 4096;

/** Last assistant message on the branch — the turn that triggered the recovery. */
function lastAssistant(entries: readonly unknown[]): AssistantMessage | undefined {
	for (let i = entries.length - 1; i >= 0; i--) {
		const e = entries[i] as { type?: string; message?: { role?: string } };
		if (e.type === "message" && e.message?.role === "assistant") return e.message as AssistantMessage;
	}
	return undefined;
}

/** One line saying which kind of "overflow" this is, with the numbers that prove it. */
export function describeOverflow(last: AssistantMessage | undefined, window: number, maxTokens: number): string {
	if (!last) return "no assistant message on the branch to inspect.";
	const u = last.usage;
	const output = u?.output ?? 0;
	const context = (u?.input ?? 0) + (u?.cacheRead ?? 0) + (u?.cacheWrite ?? 0) + output;
	const ctxStr = window > 0 ? `${context}/${window}` : `${context}`;
	const checkWindow = "check contextWindow against the server ctx-size (CLAUDE.md > Compaction tuning).";

	if (last.stopReason === "error") {
		return `the server rejected the request at context ${ctxStr} (${last.errorMessage ?? "no message"}) — a real overflow; ${checkWindow}`;
	}
	if (last.stopReason === "length") {
		if (output === 0 && window > 0 && context >= window * 0.99) {
			return `the server produced no tokens at context ${ctxStr} — the prompt alone filled the window; ${checkWindow}`;
		}
		if (window > 0 && context >= window - 64) {
			return (
				`the server ran out of context mid-reply (${ctxStr}, output ${output}/${maxTokens}) — the prompt was ` +
				`under-estimated (big tool results or images count more than chars ÷ 4); not a reserveTokens problem.`
			);
		}
		if (maxTokens > 0 && output < maxTokens) {
			const estimate = window > 0 ? ` pi's estimate at request time ≈ ${window - PI_CONTEXT_SAFETY_TOKENS - output}, server-side context ${ctxStr}.` : "";
			return (
				`truncated-reply recovery, NOT a full window: the reply stopped at ${output} of ${maxTokens} max tokens, ` +
				`so pi had clamped max_tokens to window − estimate − ${PI_CONTEXT_SAFETY_TOKENS}.${estimate} ` +
				`reserveTokens is not the knob — see CLAUDE.md > Compaction tuning > max_tokens clamp.`
			);
		}
	}
	return `stopReason ${last.stopReason}, context ${ctxStr}, output ${output}/${maxTokens} — input reported above the declared window; ${checkWindow}`;
}

export default function (pi: ExtensionAPI) {
	let overflowCount = 0;

	pi.on("session_before_compact", async (event, ctx) => {
		if (!ctx.hasUI) return undefined;

		if (event.reason === "overflow") {
			overflowCount++;
			const model = ctx.model;
			const verdict = describeOverflow(lastAssistant(event.branchEntries), model?.contextWindow ?? 0, model?.maxTokens ?? 0);
			ctx.ui.notify(`Compacting in OVERFLOW recovery (#${overflowCount}) — ${verdict}`, "warning");
		}

		// Never alter the compaction itself — observe only.
		return undefined;
	});

	pi.on("session_compact", async (event, ctx) => {
		if (!ctx.hasUI) return;

		const reason = event.reason ?? "unknown";
		const retrying = event.willRetry ? ", retrying the aborted turn" : "";
		const level = reason === "overflow" ? "warning" : "info";

		ctx.ui.notify(`Compacted (${reason}${retrying})`, level);
	});
}
