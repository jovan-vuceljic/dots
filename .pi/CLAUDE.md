# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

This is **not application source** — it's the on-disk configuration tree for `pi`, the TUI coding agent from [earendil-works/pi](https://github.com/earendil-works/pi) (binary at `/usr/bin/pi`). It lives inside the user's dots repo (`~/.dots`) and is surfaced into `$HOME` via GNU Stow's per-file symlinks (`--no-folding`), e.g. `~/.pi/agent/extensions/notify.ts -> ../../../.dots/common/.pi/agent/extensions/notify.ts`. **Editing** an existing file edits the live config directly — no deploy step. But **adding a new file** (e.g. a new extension) is not surfaced until you re-stow: run `./install.sh` (or `stow --no-folding -R -d ~/.dots -t ~ common`) to create its symlink, on each machine.

Because it's JSON + markdown config, there are no tests/lint/build. The only useful "validation" is JSON well-formedness, e.g. `jq . settings.json` or `python -m json.tool < settings.json`.

## Config directory — single source of truth

**All live config is `.pi/agent/`** (surfaced as `~/.pi/agent`). The pi coding agent reads `$PI_CODING_AGENT_DIR`, which defaults to `~/.pi/agent` and is not overridden here; per pi's docs, settings/auth/trust/sessions/extensions/AGENTS.md all resolve under that one directory. Nothing reads `~/.pi/*` at the top level or `~/.config/pi`.

> History: there used to be three drifted copies of this config (`.pi/*` top-level, `.pi/agent/`, and `~/.config/pi/`). The two unread mirrors were deleted and the dangling `~/.config/pi` stow symlink removed, leaving `.pi/agent/` as the only copy. Don't reintroduce mirrors — edit `.pi/agent/` directly.

## Layout of `.pi/agent/` (the live config)

- `settings.json` — runtime settings: `defaultProvider`/`defaultModel`/`defaultThinkingLevel`, `theme`, `enabledModels` (glob allowlist for the Ctrl+P model picker), `compaction` (auto-summarize long sessions), `retry`, HTTP timeouts, and `npmCommand` (pinned to `fnm exec --using=22 -- npm`).
- `models.json` — the provider + model catalog (see below).
- `auth.json` — maps each provider to its credential. Values are **references, not secrets** (`$DUSKADIY_API_KEY`, `no-key-required`); pi resolves `$VAR` from the environment.
- `prompts/*.md` — custom slash commands (pi "prompt templates"). `/commit` and `/review` are defined here. Format: YAML frontmatter (`description`, `argument-hint`) + body, with `${1:-default}` positional-arg substitution.
- `themes/*.json` — color themes following the schema at `earendil-works/pi .../theme/theme-schema.json`: a `vars` palette referenced by semantic `colors` keys, plus an `export` block for HTML session export.
- `sessions/` — runtime session transcripts (`.jsonl`), **gitignored**. One subdir per project cwd; each line is an event (`session`, `model_change`, `message`, …).
- `extensions/*/index.ts` — auto-discovered TypeScript extensions, loaded via [jiti](https://github.com/unjs/jiti) (no build step). `import type` from `@earendil-works/*` is erased at runtime; value imports resolve against pi's own bundled packages, so a vendored extension needs no `node_modules`. Editor TS "cannot find module" warnings on these imports are therefore expected noise.
- `keybindings.json` — key remaps. A user entry **replaces** the default keys for that action (it does not merge). Action ids and defaults are listed in `/opt/pi-coding-agent/docs/keybindings.md`.

## Plan mode (Shift+Tab)

`extensions/plan-mode/` is pi's bundled plan-mode example (pi has no built-in plan mode), **vendored here and rebound from its upstream `Ctrl+Alt+P` to Shift+Tab**. In plan mode it disables `edit`/`write` and restricts `bash` to a read-only allowlist (footer shows `⏸ plan`); `/plan` also toggles it, `--plan` starts in it. The rebind is two coupled edits — keep them together:

- `extensions/plan-mode/index.ts` (~line 157): `pi.registerShortcut("shift+tab", …)`, and the upstream `import { Key } … }` is removed. This file is a **local fork** of `/opt/pi-coding-agent/examples/extensions/plan-mode/`; on a pi upgrade, re-pull from there and re-apply these two edits.
- `keybindings.json` moves `app.thinking.cycle` off Shift+Tab to `ctrl+shift+t`, so the toggle fires deterministically (otherwise it collides with the built-in thinking-cycle binding).

After editing an extension or `keybindings.json`, run `/reload` in pi to apply without restarting.

## Status bar (custom footer)

`extensions/statusbar.ts` replaces pi's default footer via `ctx.ui.setFooter()`. It
mirrors the Claude Code status line (`~/.config/claude/statusline.py`) but swaps the
emoji for **Nerd Font (Material Design) glyphs** — the same family already used in
tmux (waybar cpu/mem/net glyphs) and nvim — so it renders natively in kitty
(CaskaydiaCove Nerd Font Mono). Colors come from the active theme, not raw ANSI.

Icon legend (each glyph echoes the Claude emoji it stands in for):

| Glyph | Codepoint | Segment | ~ Claude |
|---|---|---|---|
| `󰉋` | `U+F024B` nf-md-folder | cwd (`~`-collapsed) | 📁 |
| `󰘬` | `U+F062C` nf-md-source_branch | git branch | 🌿 |
| `󰚩` | `U+F06A9` nf-md-robot | model id + `· thinking` | 🤖 |
| `󰈚` | `U+F021A` nf-md-text_box | context-window % used (+ tokens) | 📝 |
| `󰓅` | `U+F04C5` nf-md-speedometer | last response's decode throughput (t/s) | — |
| `󰀪` | `U+F002A` nf-md-alert_outline | context-budget warning widget (above editor, ≥80%) | — |
| `↑ ↓` | — | session input / output tokens | 💰 |

Two extras beyond the footer line: a themed "breathing" pulse **working-indicator**
(the streaming spinner), and a **context-budget warning widget** above the editor
that appears once the window is ≥80% full (`warning`, then `error` ≥90%) nudging a
`/compact`. Both are reset when the footer is toggled off.

Segments render left→right and truncate at the terminal edge. git only shows inside
a git repo; context, t/s and tokens only appear after the first response (t/s is
`usage.output ÷ (message_end − first streamed token)`, so prompt-eval time is
excluded). Extension statuses (e.g. plan-mode's `⏸ plan`) are preserved at the far
left. The Claude bar's system row (RAM/CPU/temp/disk) is intentionally omitted —
that data isn't in the footer API, and the tmux bar below pi already shows
cpu/mem/net. `/statusbar` toggles it off (restores the built-in footer) and back on;
`/reload` picks up edits to this file (a *new* extension needs a re-stow first — see
top).

## Vim input editor

`extensions/vim-editor.ts` swaps pi's input editor for a modal (vim-like) one via
`ctx.ui.setEditorComponent()`. Three modes; the **active** one is shown as a single
lit tag overlaid at the **bottom-left** of the editor border — `[I]` insert (green),
`[N]` normal (mauve), `[V]` visual (peach). The overlay uses a small `dropLeftCols`
helper so it replaces the border's leftmost cells while keeping the border's color
and right corner intact.

- **INSERT** — normal typing; Esc → NORMAL.
- **NORMAL** — `hjkl` move · `w`/`b` word · `0`/`$` line ends · `gg`/`G` buffer
  top/bottom · `x` del char · `D` del to EOL · `dd` clear line · `cc` change line ·
  `yy` yank line · `p` paste · `[count]` prefix (`3j`, `5x`) · `i`/`a` insert
  before/after · `I`/`A` insert at line start/end · `v` → VISUAL. Esc cancels a
  pending count/operator; with nothing pending it aborts the agent (pi default), so
  aborting mid-stream is Esc(-Esc).
- **VISUAL** — `hjkl`/`0`/`$` extend selection (shift-arrows) · `d`/`x` delete it ·
  Esc → NORMAL. (Selection depends on pi's editor honoring shift-arrow keys.)

`yy`/`dd`/`p` ride pi's editor **kill-ring** (`ctrl+k` kills, `ctrl+y` pastes), so
yank/delete-then-paste round-trips. `dd`/`cc` clear the current line's text (they
don't remove the line); `gg`/`G` use ctrl+Home/End (best-effort). Counts are clamped
to 200.

`/vim` toggles it off/on. The tag uses `ctx.ui.theme.fg` **guarded**
(`typeof theme.fg === "function"`) because the theme passed to the editor factory
lacks `.fg` — calling it there crashed the TUI (fixed 2026-07-18). It's a **local
fork** of pi's bundled example `/opt/pi-coding-agent/examples/extensions/modal-editor.ts`
(theming, visual mode, left `[I]/[N]/[V]` indicator added) — on a pi upgrade, re-pull
and re-apply, same as plan-mode.

## Compaction tuning (small local windows)

`settings.json > compaction` is set for the small local context windows (24k–128k;
several presets are only 24k). `reserveTokens: 6144` (headroom for the
response; auto-compaction fires at `contextTokens > contextWindow − reserveTokens`)
and `keepRecentTokens: 6000` (kept verbatim, not summarized) — both well below pi's
16384/20000 defaults so short windows aren't dominated by the reserve or thrash into
repeated compaction. These are **global** (pi has no per-model compaction): on the
128k model you could raise `keepRecentTokens` for richer retained context; if you
see responses truncate near a full window, raise `reserveTokens` toward the models'
`maxTokens` (8192). All model `contextWindow`s are verified to match the server
`ctx-size` in `fl/.config/llamacpp/config.ini`.

## Providers and models

Two OpenAI-compatible providers are configured, both serving the same catalog of small local/self-hosted models (Qwen3-Coder-30B, Gemma 4, GLM-4.7-Flash, etc.). All have `cost: 0`:

- **`duskadiy`** — remote, `https://llm.duskadiy.com/api/v1`, key `$DUSKADIY_API_KEY`.
- **`localcpp`** — LAN llama.cpp server at `http://192.168.0.204:11343/v1`, no key.

When adding/editing a model, keep `id` exactly matching the server's model id (the section name in `fl/.config/llamacpp/config.ini`), and set `contextWindow` to match the `ctx-size` the model is actually loaded with server-side.

## Secrets

`$DUSKADIY_API_KEY` is the only real secret. It is defined in `.config/fish/conf.d/secrets.fish` (gitignored) and referenced — never inlined — in tracked config. Keep it that way: tracked files (`auth.json`, `models.json`) must contain `$DUSKADIY_API_KEY`, not the literal token.

⚠️ `auth.json` is git-tracked but pi's interactive `/login` writes the **literal** key into it — don't use `/login` for `duskadiy` (or `git rm --cached auth.json` first), or a real token will land in a commit. Installed-package and runtime artifacts (`.pi/agent/npm/`, `git/`, `trust.json`, `sessions/`) are gitignored.

## Running pi

- `pi` — interactive TUI. `pi -p "<prompt>"` — non-interactive, print and exit.
- `pi -c` / `pi -r` — continue / pick a session to resume.
- `pi config` — TUI to enable/disable discovered resources. `pi --list-models [search]` — list available models.
- `--provider` / `--model` / `--thinking` override the `settings.json` defaults per-run.
- pi also auto-discovers `CLAUDE.md`/`AGENTS.md` as context files (disable with `-nc`) — i.e. pi reads this very file too, not just Claude Code.
