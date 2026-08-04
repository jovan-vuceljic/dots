/**
 * Vim input editor
 *
 * Replaces pi's input editor with a modal (vim-like) one via
 * `ctx.ui.setEditorComponent()`. Starts in INSERT mode, so normal typing works
 * out of the box. The *active* mode is shown at the bottom-**left** of the editor
 * border as a single lit tag — `[I]` insert (green), `[N]` normal (mauve),
 * `[V]` visual (peach).
 *
 * Local fork of pi's bundled example `/opt/pi-coding-agent/examples/extensions/
 * modal-editor.ts` — on a pi upgrade, re-pull from there and re-apply the theming,
 * the visual mode, the mode indicator, and the motions below. (Same vendoring
 * convention as plan-mode/.)
 *
 * Modes & keys:
 *   INSERT  normal typing; Esc → NORMAL
 *   NORMAL  h j k l move · w b word · 0 $ line ends · gg / G buffer top/bottom
 *           x del char · D del to EOL · dd clear line · cc change line
 *           yy yank line · p paste (editor kill-ring) · [count] prefix, e.g. 3j, 5x
 *           i/a insert before/after · I/A insert at line start/end · v → VISUAL
 *           Esc cancels a pending count/operator; with none pending it aborts the
 *           agent (pi default) — so aborting mid-stream is Esc(-Esc)
 *   VISUAL  h j k l / 0 $ extend selection (shift-arrows) · d/x delete selection
 *           Esc → NORMAL
 *
 * yank/paste/delete ride pi's built-in editor kill-ring (ctrl+k kills, ctrl+y
 * pastes), so `dd`/`yy` then `p` round-trips text. `dd`/`cc` clear the current
 * line's text (leave the line); `gg`/`G` use ctrl+Home/End (best-effort, depends on
 * the editor honoring them). Restore pi's default editor with `/vim`.
 */

import { CustomEditor, type ExtensionAPI, type ExtensionContext, type Theme } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

type Mode = "insert" | "normal" | "visual";
type Pending = "" | "d" | "y" | "c" | "g";

// Repeatable NORMAL-mode motions/edits → escape sequence for the line editor.
// (Counts repeat these; mode switches and operators are handled explicitly below.)
const NORMAL_MOTIONS: Record<string, string> = {
	h: "\x1b[D", // left
	j: "\x1b[B", // down
	k: "\x1b[A", // up
	l: "\x1b[C", // right
	"0": "\x01", // line start (ctrl+a)
	$: "\x05", // line end (ctrl+e)
	w: "\x1bf", // word forward (alt+f)
	b: "\x1bb", // word back (alt+b)
	x: "\x1b[3~", // delete char under cursor
	D: "\x0b", // delete to end of line (ctrl+k)
};

// VISUAL-mode movement → shift+arrow, which extends the editor's selection.
const VISUAL_KEYS: Record<string, string> = {
	h: "\x1b[1;2D", // shift+left
	l: "\x1b[1;2C", // shift+right
	j: "\x1b[1;2B", // shift+down
	k: "\x1b[1;2A", // shift+up
	"0": "\x1b[1;2H", // shift+home
	$: "\x1b[1;2F", // shift+end
};

const HOME = "\x01"; // ctrl+a  line start
const KILL_EOL = "\x0b"; // ctrl+k  kill to end of line (into the editor kill-ring)
const YANK = "\x19"; // ctrl+y  paste most-recently-killed text
const MAX_COUNT = 200; // clamp so a fat-fingered "999j" can't spin

const MODE_LETTER: Record<Mode, string> = { insert: "I", normal: "N", visual: "V" };
const MODE_COLOR: Record<Mode, string> = { insert: "success", normal: "accent", visual: "warning" };

// The active pi theme, captured from `ctx.ui.theme` (which has `.fg`, unlike the
// theme object passed to the editor factory). Used to color the mode indicator.
let theme: Theme | undefined;

const SGR = /\x1b\[[0-9;]*m/y; // ANSI color code, matched at a fixed position

/** Drop the first `n` *visible* columns of `s`, carrying any color codes that were
 *  active before the cut into the remainder — so we can overlay a label on the left
 *  of a colored border without losing the border's color on the kept tail. */
function dropLeftCols(s: string, n: number): string {
	let i = 0;
	let col = 0;
	let codes = "";
	while (i < s.length && col < n) {
		if (s.charCodeAt(i) === 0x1b) {
			SGR.lastIndex = i;
			const m = SGR.exec(s);
			if (m) {
				codes += m[0];
				i += m[0].length;
				continue;
			}
		}
		col++;
		i++;
	}
	return codes + s.slice(i);
}

class VimEditor extends CustomEditor {
	private mode: Mode = "insert";
	private count = ""; // pending numeric prefix, e.g. "3"
	private pending: Pending = ""; // pending operator awaiting its double (dd/yy/cc/gg)

	private reset(): void {
		this.count = "";
		this.pending = "";
	}

	handleInput(data: string): void {
		if (matchesKey(data, "escape")) {
			if (this.mode === "insert" || this.mode === "visual") {
				this.mode = "normal";
				this.reset();
			} else if (this.count || this.pending) {
				this.reset(); // first Esc cancels a pending count/operator
			} else {
				super.handleInput(data); // then Esc aborts the agent
			}
			return;
		}

		if (this.mode === "insert") {
			super.handleInput(data);
			return;
		}
		if (this.mode === "visual") {
			this.handleVisual(data);
			return;
		}
		this.handleNormal(data);
	}

	private repeat(seq: string, times: number): void {
		for (let n = 0; n < times; n++) super.handleInput(seq);
	}

	/** Execute a doubled operator (dd / cc / yy / gg). */
	private applyDoubled(op: Pending): void {
		switch (op) {
			case "d": // clear the current line (kill it into the ring)
				super.handleInput(HOME);
				super.handleInput(KILL_EOL);
				break;
			case "c": // change: clear the line, then insert
				super.handleInput(HOME);
				super.handleInput(KILL_EOL);
				this.mode = "insert";
				break;
			case "y": // yank the line: kill then paste back (copies into the ring, text intact)
				super.handleInput(HOME);
				super.handleInput(KILL_EOL);
				super.handleInput(YANK);
				break;
			case "g": // gg → buffer start (best-effort ctrl+Home)
				super.handleInput("\x1b[1;5H");
				break;
		}
	}

	private handleNormal(data: string): void {
		// Numeric count prefix: 1-9 always; 0 only extends an in-progress count
		// (a lone 0 is the line-start motion).
		if (data >= "0" && data <= "9" && !(data === "0" && this.count === "")) {
			if (this.count.length < 3) this.count += data;
			return;
		}

		// Complete or cancel a pending operator (dd/yy/cc/gg only).
		if (this.pending) {
			const op = this.pending;
			this.pending = "";
			if (data === op || (op === "g" && data === "g")) {
				this.applyDoubled(op);
				this.count = "";
				return;
			}
			// otherwise fall through and process `data` as a fresh key
		}

		const times = Math.min(Math.max(parseInt(this.count || "1", 10) || 1, 1), MAX_COUNT);
		this.count = "";

		// Operators wait for their double.
		if (data === "d" || data === "y" || data === "c" || data === "g") {
			this.pending = data;
			return;
		}

		switch (data) {
			case "G":
				super.handleInput("\x1b[1;5F"); // buffer end (best-effort ctrl+End)
				return;
			case "p":
				this.repeat(YANK, times); // paste from the kill-ring
				return;
			case "i":
				this.mode = "insert";
				return;
			case "a":
				this.mode = "insert";
				super.handleInput("\x1b[C"); // step right, then insert
				return;
			case "I":
				this.mode = "insert";
				super.handleInput(HOME);
				return;
			case "A":
				this.mode = "insert";
				super.handleInput("\x05"); // line end
				return;
			case "v":
				this.mode = "visual";
				return;
		}

		if (data in NORMAL_MOTIONS) {
			this.repeat(NORMAL_MOTIONS[data]!, times);
			return;
		}
		// Let control sequences (ctrl+c, ctrl+d, …) through; swallow printable keys.
		if (data.length === 1 && data.charCodeAt(0) >= 32) return;
		super.handleInput(data);
	}

	private handleVisual(data: string): void {
		if (data in VISUAL_KEYS) {
			super.handleInput(VISUAL_KEYS[data]!);
			return;
		}
		// d / x delete the current selection, then drop back to normal.
		if (data === "d" || data === "x") {
			super.handleInput("\x7f"); // backspace removes the selected span
			this.mode = "normal";
			return;
		}
		if (data.length === 1 && data.charCodeAt(0) >= 32) return;
		super.handleInput(data);
	}

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length === 0) return lines;

		const raw = `[${MODE_LETTER[this.mode]}]`; // active mode only, visible width 3
		// Guard `.fg` defensively: render() runs on every keystroke, so a bad theme
		// must degrade to plain text, never throw (that would crash the whole TUI).
		const label = theme && typeof theme.fg === "function" ? theme.fg(MODE_COLOR[this.mode], raw) : raw;

		const last = lines.length - 1;
		if (visibleWidth(lines[last]!) > raw.length) {
			// Overlay the tag on the far left, over the border's first `raw.length`
			// cells, keeping the rest of the border (incl. its right corner) intact.
			lines[last] = label + dropLeftCols(lines[last]!, raw.length);
		}
		return lines;
	}
}

export default function (pi: ExtensionAPI) {
	let enabled = true;

	const install = (ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;
		theme = ctx.ui.theme; // the ExtensionTheme (has `.fg`); the factory's theme arg does not
		ctx.ui.setEditorComponent((tui, th, kb) => new VimEditor(tui, th, kb));
	};

	pi.on("session_start", async (_event, ctx) => {
		if (enabled) install(ctx);
	});

	pi.registerCommand("vim", {
		description: "Toggle the vim (modal) input editor",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			if (enabled) {
				install(ctx);
				ctx.ui.notify("Vim editor enabled", "info");
			} else {
				ctx.ui.setEditorComponent(undefined);
				ctx.ui.notify("Default editor restored", "info");
			}
		},
	});
}
