/**
 * Permission Gate Extension
 *
 * Prompts for confirmation before running potentially dangerous bash commands.
 *
 * Adapted from pi's bundled `examples/extensions/permission-gate.ts`. Upstream checks
 * three patterns (rm -rf, sudo, chmod/chown 777); the list below is extended to cover
 * the rules AGENTS.md only *asks* for. That distinction is the whole point of running
 * this: AGENTS.md is a prompt, and the small local models this config targets follow
 * prompts unreliably. This is the enforcement half — the same trick plan-mode already
 * uses when it disables edit/write outright.
 *
 * In the TUI a match prompts (so "Yes" still gets you through); with no UI it blocks.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const dangerousPatterns = [
		// --- upstream ---
		/\brm\s+(-rf?|--recursive)/i,
		/\bsudo\b/i,
		/\b(chmod|chown)\b.*777/i,

		// --- LOCAL: git history is the user's to write, never the agent's ---
		// The standing rule is that commits and pushes are made by hand, after review.
		/\bgit\s+(commit|push|revert)\b/i,
		/\bgit\s+reset\s+--hard\b/i,
		/\bgit\s+(rebase|cherry-pick)\b/i,
		/\bgit\s+clean\s+-[a-z]*[fd]/i,
		/\bgit\s+stash\s+(drop|clear|pop)\b/i,
		/--force\b|--force-with-lease\b/i,

		// --- LOCAL: system-changing commands AGENTS.md rules out ---
		/\b(pacman|yay|paru)\s+-[A-Za-z]*[SRU]/,
		/\b(npm|pnpm|yarn)\s+(install|i|add|remove|uninstall)\b/i,
		/\bpip3?\s+(install|uninstall)\b/i,
		/\bcargo\s+(install|uninstall)\b/i,
		/\bsystemctl\s+(start|stop|restart|enable|disable|mask)\b/i,

		// --- LOCAL: irreversible disk / process operations ---
		/\bmkfs\b|\bdd\s+if=|\bshred\b|\bwipefs\b/i,
		/\b(reboot|shutdown|poweroff|halt)\b/i,
		/\b(killall|pkill)\b/i,
		/>\s*\/dev\/(sd|nvme|vd)/i,
	];

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;

		const command = event.input.command as string;
		const matched = dangerousPatterns.find((p) => p.test(command));

		if (matched) {
			if (!ctx.hasUI) {
				// Non-interactive (`pi -p`): nothing can confirm, so refuse.
				return { block: true, reason: "Dangerous command blocked (no UI for confirmation)" };
			}

			const choice = await ctx.ui.select(`⚠️ Dangerous command:\n\n  ${command}\n\nAllow?`, ["Yes", "No"]);

			if (choice !== "Yes") {
				return { block: true, reason: "Blocked by user" };
			}
		}

		return undefined;
	});
}
