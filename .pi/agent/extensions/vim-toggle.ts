/**
 * `/vim` — toggle the modal input editor off/on
 *
 * The modal editor itself is now the **npm package `pi-vim`** (declared in
 * `settings.json > packages`, configured under `settings.json > piVim`). That
 * package registers no commands, so this file restores the `/vim` toggle the
 * local `vim-editor.ts` fork used to provide — the fork is kept beside it as
 * `vim-editor.ts.disabled` (see ../../CLAUDE.md).
 *
 * OFF — drop the custom editor component, which puts pi's stock editor back for
 *       the rest of the session (handy for a big paste, or any key the modal
 *       layer swallows).
 * ON  — `ctx.reload()`, the same flow as `/reload`, re-runs extension discovery
 *       and so re-installs pi-vim's editor. That reloads statusbar/plan-mode too
 *       and re-instantiates *this* file, which is why turning it back on needs no
 *       bookkeeping: the fresh instance starts at `enabled = true` again.
 *
 * Nothing is installed on `session_start` — pi-vim already does that, so this
 * file only ever reacts to the command and never races it for the editor slot.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	// pi-vim installs its editor at session_start, so we start out enabled.
	let enabled = true;

	pi.registerCommand("vim", {
		description: "Toggle the vim (modal) input editor",
		handler: async (_args, ctx) => {
			if (ctx.mode !== "tui") return; // editor components are TUI-only
			if (enabled) {
				ctx.ui.setEditorComponent(undefined);
				enabled = false;
				ctx.ui.notify("Default editor restored — /vim to re-enable", "info");
				return;
			}
			// Notify *before* awaiting: after the reload this call frame belongs to
			// the pre-reload instance, and its UI handle is on the way out.
			ctx.ui.notify("Vim editor enabled", "info");
			await ctx.reload();
		},
	});
}
