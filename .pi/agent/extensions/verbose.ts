/**
 * Verbose view toggle — `/verbose` and a bound key.
 *
 * The counterpart of the opencode TUI plugin and the Claude `/verbose` skill, adjusted for
 * what pi actually allows. pi splits verbosity in two:
 *
 *   LIVE     `ctrl+o` (app.tools.expand) collapses/expands tool output and `ctrl+t`
 *            (app.thinking.toggle) does the same for thinking blocks. These are built-in
 *            keybindings. An extension cannot drive them — there is no settings API and no
 *            way to dispatch a built-in action — and a key maps to one action, so they
 *            cannot be merged into a single press the way opencode's four toggles were.
 *
 *   PERSISTED  `hideThinkingBlock` and `showCacheMissNotices` in settings.json, read at
 *            startup. That is what this toggles, i.e. the default you get on every new
 *            session, which is exactly the position the Claude skill is in.
 *
 * So: this sets the default and tells you the live keys. "on" shows thinking and the
 * cache/compaction/recovery notices; "off" is deliberately quieter than stock pi (it hides
 * thinking), matching how opencode's verbose-off state hides thinking too.
 *
 * ⚠️ pi writes settings.json itself (that is where `lastChangelogVersion` churn comes from),
 * so a running pi may overwrite this on exit. If a toggle seems not to have stuck, re-run it
 * after pi has exited.
 */

import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type Settings = Record<string, unknown>;

const LIVE = "live now: ctrl+o tool output, ctrl+t thinking";

// Verbose-on values. Verbose-off is the inverse, not pi's defaults: stock pi already shows
// thinking (hideThinkingBlock defaults to false), so an "off" that merely restored defaults
// would be indistinguishable from "on" for the noisiest part.
const VERBOSE_ON: Settings = { hideThinkingBlock: false, showCacheMissNotices: true };
const VERBOSE_OFF: Settings = { hideThinkingBlock: true, showCacheMissNotices: false };

function settingsPath(): string {
	return join(getAgentDir(), "settings.json");
}

function read(): Settings {
	// A parse failure must never lead to a write — that would replace a hand-edited config
	// with whatever this extension thinks it knows.
	const raw = readFileSync(settingsPath(), "utf-8");
	return JSON.parse(raw) as Settings;
}

function isOn(s: Settings): boolean {
	return s.hideThinkingBlock === false && s.showCacheMissNotices === true;
}

function write(s: Settings): void {
	// Plain writeFileSync, deliberately NOT write-temp-then-rename: this path is a stow
	// symlink into the dots repo, and renaming over it would replace the link with a real
	// file, silently detaching the live config from the repo.
	writeFileSync(settingsPath(), `${JSON.stringify(s, null, 2)}\n`, "utf-8");
}

function describe(s: Settings): string {
	return `hideThinkingBlock: ${s.hideThinkingBlock ?? false}, showCacheMissNotices: ${s.showCacheMissNotices ?? false}`;
}

function toggle(ctx: ExtensionContext, mode: "on" | "off" | "toggle" | "status"): void {
	let current: Settings;
	try {
		current = read();
	} catch (err) {
		ctx.ui.notify(`verbose: cannot read settings.json — ${err}`, "error");
		return;
	}

	if (mode === "status") {
		ctx.ui.notify(`Verbose ${isOn(current) ? "ON" : "OFF"} — ${describe(current)}. ${LIVE}`, "info");
		return;
	}

	const on = mode === "toggle" ? !isOn(current) : mode === "on";
	const next = { ...current, ...(on ? VERBOSE_ON : VERBOSE_OFF) };

	try {
		write(next);
	} catch (err) {
		ctx.ui.notify(`verbose: cannot write settings.json — ${err}`, "error");
		return;
	}

	ctx.ui.notify(
		`Verbose ${on ? "ON" : "OFF"} — applies to new sessions (settings are read at startup). ${LIVE}`,
		"info",
	);
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("verbose", {
		description: "Toggle the persisted verbose view (usage: /verbose [on|off|status])",
		handler: async (args, ctx) => {
			const raw = args.trim().toLowerCase();
			if (raw && raw !== "on" && raw !== "off" && raw !== "status") {
				ctx.ui.notify("usage: /verbose [on|off|status]", "error");
				return;
			}
			toggle(ctx, (raw || "toggle") as "on" | "off" | "toggle" | "status");
		},
	});

	pi.registerShortcut("alt+v", {
		description: "Toggle verbose view",
		handler: async (ctx) => toggle(ctx, "toggle"),
	});
}
