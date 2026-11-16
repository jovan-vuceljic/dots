/**
 * Pi agent-state extension: mirrors Pi's state into the tmux pane it runs in via
 * ~/.config/tmux/scripts/agent-state.sh (pi busy|done|input|off), so the tmux status bar
 * shows which pane is done or waiting for you. The script is a no-op outside tmux.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

const SCRIPT = join(homedir(), ".config", "tmux", "scripts", "agent-state.sh");

function state(s: "busy" | "done" | "input" | "error" | "off"): void {
	if (!process.env.TMUX_PANE) return;
	execFile(SCRIPT, ["pi", s], () => {});
}

export default function (pi: ExtensionAPI) {
	pi.on("agent_start", async () => state("busy"));
	// agent_settled, not agent_end: Pi may still retry, compact, or run queued follow-ups.
	pi.on("agent_settled", async () => state("done"));
	// Blocking confirm/select prompts from extensions (permission-gate, confirm-destructive, questionnaire).
	pi.on("ui_prompt_start", async () => state("input"));
	pi.on("ui_prompt_end", async () => state("busy"));
	pi.on("session_shutdown", async () => state("off"));
}
