# pi config (`~/.pi`)

On-disk configuration for **[pi](https://github.com/earendil-works/pi)**, a TUI coding
agent (binary `/usr/bin/pi`). This tree lives in the dots repo and is surfaced into
`$HOME` by GNU Stow, so `~/.pi/agent/...` symlinks back here — **editing a file here
edits the live config**, no deploy step.


## Install / how it's surfaced

pi reads everything under `$PI_CODING_AGENT_DIR` (default `~/.pi/agent`). Stow
symlinks each file individually (`--no-folding`):

```
~/.pi/agent/settings.json -> ~/.dots/common/.pi/agent/settings.json
~/.pi/agent/extensions/statusbar.ts -> ~/.dots/common/.pi/agent/extensions/statusbar.ts
...
```

- **Editing** an existing tracked file = editing live config immediately.
- **Adding** a new file (e.g. a new extension) is *not* live until you re-stow —
  run `./install.sh` (or `stow --no-folding -R -d ~/.dots -t ~ common`) once to
  create the symlink.
- After editing an extension, prompt, theme, or `keybindings.json`, run `/reload`
  inside pi to apply without restarting.

## What's in here

| Path | Purpose |
|---|---|
| `agent/settings.json` | runtime settings (default model, theme, compaction, retry, timeouts) |
| `agent/models.json` | provider + model catalog (two OpenAI-compatible providers) |
| `agent/auth.json` | provider → credential map (references like `$DUSKADIY_API_KEY`, never literals). **Untracked** — copy `auth.json.example` on a new host |
| `agent/keybindings.json` | key remaps (each entry **replaces** the default for that action) |
| `agent/AGENTS.md` | global system instructions injected into every session |
| `agent/prompts/*.md` | custom `/slash` commands (prompt templates) |
| `agent/themes/*.json` | custom color themes |
| `agent/extensions/**` | auto-discovered TypeScript extensions (loaded via jiti, no build) |

Runtime artifacts (`sessions/`, `npm/`, `git/`, `trust.json`) are gitignored.

---

## Addons vs. stock pi

Stock pi ships with **no extensions enabled, two built-in themes (`dark`/`light`),
default keybindings, and default settings**. Everything below is a deviation added
here. Each is independent — pull the ones you want and delete the rest.

### Extensions

pi **auto-discovers** every `.ts` under `extensions/`. So the universal "remove"
step is: **delete the file (or its folder) and `/reload`.** Toggle-able ones also
have a slash command to disable them for the current session without deleting.

| Extension | What it adds | Origin | Remove |
|---|---|---|---|
| `statusbar.ts` | Replaces the footer with a Claude-Code-style status line (cwd, git branch, model, context %, decode t/s, token counts) in Nerd Font glyphs; adds a streaming pulse + a ≥80%-context warning widget | **custom** | delete file → default footer returns; or `/statusbar` to toggle off for the session |
| `vim-toggle.ts` | `/vim` — drops the modal editor for the rest of the session, and brings it back via `ctx.reload()`. Pairs with the **`pi-vim` package** (below), which registers no command of its own | **custom** | delete file → you lose the toggle, not the editor; remove the package to drop modal editing itself |
| `plan-mode/` | Read-only "plan" mode (disables edit/write; allowlisted read-only bash runs freely, any other command asks Yes/No first) bound to **Shift+Tab**; `/plan` toggles, `--plan` starts in it, `/plan-done` clears a stuck progress checklist | **vendored** copy of pi's bundled `examples/extensions/plan-mode/`, rebound from upstream `Ctrl+Alt+P`; upstream blocks non-allowlisted bash instead of asking, and re-offers a stale plan after every later answer | delete the folder **and** revert the `keybindings.json` `app.thinking.cycle` remap (see below) |
| `chat-mode.ts` | Question-answering mode: **Alt+C** or `/chat [on\|off]` toggles, `--chat` starts in it (footer `💬 chat`). The model is told to just answer (no plan, no implementing); every `bash` command and every `edit`/`write` asks Yes/No first, while `read`/`grep`/`find`/`ls` stay free. Defers to plan mode while that is on. Note `pi -p --chat "q"` swallows the prompt as the flag's value, so put `--chat` earlier | **custom** | delete file |
| `notify.ts` | Native terminal notification (OSC 777/99, Windows toast) when the agent goes idle | **verbatim** from pi's `examples/extensions/notify.ts` | delete file |
| `agent-state.ts` | Mirrors Pi's state (`agent_start` busy, `agent_settled` done, `ui_prompt_*` input, `session_shutdown` off) into the tmux pane it runs in via `~/.config/tmux/scripts/agent-state.sh`, for the status-bar agent badges; no-op outside tmux | own | delete file |
| `questionnaire.ts` | Interactive multi-question overlay the model can call as a tool | **near-verbatim** from pi's `examples/extensions/questionnaire.ts` (one-line fix) | delete file |
| `permission-gate.ts` | Prompts before dangerous `bash` commands (blocks outright with no UI). Local list covers git history rewrites, package managers, `systemctl` and irreversible disk ops on top of upstream's `rm -rf`/`sudo`/`chmod 777` | **adapted** from pi's `examples/extensions/permission-gate.ts` | delete file |
| `protected-paths.ts` | Blocks `write`/`edit` to secrets and repo plumbing (`secrets.fish`, `auth.json`, `.env`, `.ssh/`, `.git/`, …) | **adapted** from pi's `examples/extensions/protected-paths.ts` | delete file |
| `compaction-watch.ts` | Surfaces every compaction and its `reason`; on `overflow` (recovery rather than prevention) it reads the turn that caused it and says which kind it was, with numbers — a reply pi itself had clamped (`max_tokens` = window − estimate − 4096, the usual one on thinking models) or a prompt the server really rejected | **custom** | delete file |
| `verbose.ts` | `/verbose [on\|off\|status]` and **Alt+V** toggle the *persisted* verbose default (`hideThinkingBlock`, `showCacheMissNotices`) and report pi's live keys — `ctrl+o` tool output, `ctrl+t` thinking, which an extension cannot drive itself | **custom** | delete file; the live keys are built in and keep working |
| `confirm-destructive.ts` | Confirms before session clear / switch / fork | **verbatim** from pi's `examples/extensions/confirm-destructive.ts` | delete file |
| `session-name.ts` | `/session-name [name]` — friendly names in the session picker instead of the first message | **verbatim** from pi's `examples/extensions/session-name.ts` | delete file |
| `todo.ts` | A `todo` tool the model calls (add/toggle/list/clear) plus `/todos` to view it; state lives in tool results, so forking rewinds it correctly. Distinct from plan-mode's checklist | **verbatim** from pi's `examples/extensions/todo.ts` | delete file (it also adds a tool schema to every request) |

> The bundled examples live under pi's install prefix, which moves: it was
> `/opt/pi-coding-agent/` before 0.85 and is `/usr/lib/pi-coding-agent/` on current Arch
> packages. Rather than hardcode either, resolve it —
> `set -l PI_ROOT (dirname (readlink -f (which pi)))` — and read `$PI_ROOT/examples/extensions/`.
> That's
> where `notify`/`questionnaire`/`plan-mode` came from. `plan-mode/` is now the only
> **fork** left, so it's the only one to re-pull after a pi upgrade before re-applying
> the local edits (its header documents them). `notify`/`questionnaire` carry no edits
> worth keeping — just re-copy them. The modal editor used to be a fork of
> `modal-editor.ts` too; it was replaced by the `pi-vim` package on 2026-08-05 and the
> fork deleted on 2026-08-09 — `git show c6566af^:common/.pi/agent/extensions/vim-editor.ts`
> brings it back if ever wanted.

### Modal (vim) input — the `pi-vim` package

Modal editing is **not** an extension in this tree any more; it's the npm package
[`pi-vim`](https://github.com/lajarre/pi-vim), pinned by `settings.json > packages`
and installed into the gitignored `agent/npm/`. That swap is the point: `pi update
npm:pi-vim` instead of re-pulling and re-patching a fork on every pi upgrade.

Five modes (INSERT/NORMAL/VISUAL/V-LINE/EX) with the usual motions, operators, text
objects, undo and `.` repeat; the mode renders as a word label at the editor's
bottom-right, doubling as a pending-command display (` NORMAL 3d2w_ `). `:` dispatches
real pi commands and shells out with `:!`. No search (`/`, `?`, `n`), macros or
visual-block — upstream implements none of those.

```fish
pi install npm:pi-vim
```

> ⚠️ **This pi build needs pi-vim's peer dep installed by hand.** pi ships as a
> Bun-compiled ELF with the `@earendil-works/*` packages *embedded*, not on disk.
> pi-vim's `clipboard-mirror.ts` calls `import.meta.resolve("@earendil-works/pi-coding-agent")`
> at **module top level**, so after a bare `pi install` the resolve throws and the whole
> extension fails to load with `Cannot find module '@earendil-works/pi-coding-agent'`.
> No setting avoids it — the call runs at import time. Once per host, matching
> `pi --version` exactly:
>
> ```fish
> cd ~/.pi/agent/npm
> fnm exec --using=22 -- npm install --save-exact \
> "@earendil-works/pi-coding-agent@"(pi --version | string trim)
> ```
>
> `pi install` deliberately doesn't pull peers (it would duplicate the runtime). Costs
> ~170 MB, and wants re-pinning after every pi upgrade — hence `--save-exact`, since a
> caret range would quietly drift off `pi --version`.

Configured under `settings.json > piVim`: `modeColors` (theme tokens, not raw ANSI),
`borderSync` so the input border itself takes the mode color in NORMAL/VISUAL
(mauve/yellow) and is left to pi in INSERT/EX, `labelSync` so the label always carries
its mode color, and
`clipboardMirror: "yank"` — upstream's default `"all"` mirrors deletes too, so every
`dd`/`x` would clobber the OS clipboard. `exCommand.copyInputToClipboard` is left
**off**: it copies the composed prompt out, so upstream only honours it from the
user-global settings file.

**Remove:** `pi remove npm:pi-vim`, and delete `agent/extensions/vim-toggle.ts` plus the
`piVim` block. `@burneikis/pi-vim` and `pi-vimmode` are alternatives that need no peer
install.

### Theme

`themes/catppuccin-mocha.json` is a **custom** theme (stock pi only bundles `dark`
and `light`). `settings.json` sets `"theme": "catppuccin-mocha"`.

**Remove:** delete the file and set `"theme": "dark"` (or `"light"`) in
`settings.json`.

### Custom slash commands (prompt templates)

`prompts/commit.md` and `prompts/review.md` add `/commit` (writes a Conventional
Commits message for the staged diff, never commits) and `/review` (reviews the
working diff). Both are **custom**. Format is YAML frontmatter + body with
`${1:-default}` positional-arg substitution.

**Remove:** delete the file(s). Stock pi has no `/commit` or `/review`.

### Keybindings

`keybindings.json` overrides three actions. **A user entry replaces the default keys
for that action — it does not merge.** Action ids and their stock defaults are in
`$PI_ROOT/docs/keybindings.md` (see above for `$PI_ROOT`).

```jsonc
{
  "app.thinking.cycle":   ["alt+t"], // moved OFF Shift+Tab so plan-mode can bind it (was ctrl+shift+t = kitty new_tab, never reached pi)
  "tui.editor.cursorUp":  ["up", "ctrl+p"], // adds Ctrl+P as up (Emacs-style)
  "app.model.cycleForward": ["alt+p"]       // Alt+P cycles models
}
```

The `app.thinking.cycle` remap is **coupled to `plan-mode`**: plan-mode binds
Shift+Tab, so the thinking-cycle default (also Shift+Tab) is moved aside to avoid a
collision. If you drop plan-mode, drop that line too.

**Remove:** delete the whole file to restore all stock keybindings, or delete
individual lines to restore just those.

### `settings.json` tunings

Beyond pointing at local models, these values deviate from pi's defaults:

| Key | Value here | Stock default | Why |
|---|---|---|---|
| `compaction.reserveTokens` | `8192` | 16384 | small local windows (24k–128k), but **≥ every model's `maxTokens` + 4096**: pi clamps each request's `max_tokens` to `contextWindow − estimate − 4096`, and with 24k/4096 that clamp starts exactly at this threshold (see CLAUDE.md for the `overflow` recoveries it can still produce) |
| `compaction.keepRecentTokens` | `4000` | 20000 | keep less verbatim, to pay for the larger reserve and leave room after a compaction for the next one |
| `npmCommand` | `fnm exec --using=22 -- npm` | `npm` | pin extension npm installs to Node 22 via fnm |
| `retry` / `httpIdleTimeoutMs` | long (1h provider timeout, 10m idle) | shorter | local models can be slow to first token |
| `defaultThinkingLevel` | `medium` | — | the default model is a thinking preset (`Qwen3.6-35B-A3B-Thinking`); Alt+T cycles it per session |
| `thinkingBudgets` | `512 / 1024 / 2048 / 3072` (minimal / low / medium / high) | 1024 / 2048 / 8192 / 16384 | per-request cap on the `<think>` block, sent only for models whose `compat.thinkingTokenBudgetField` is set (`Ornith`, as `thinking_budget_tokens`). pi clamps the budget to `maxTokens − 1024`, so on a 4096-token reply the stock values collapse to 3072 and leave the answer 1024 tokens — the recipe for "Response was truncated before completion." |
| `packages` | `["npm:pi-vim"]` | `[]` | the modal editor — see the pi-vim section above |
| `piVim` | mode colors, border painted per mode (NORMAL/VISUAL), `clipboardMirror: "yank"`, `:` → pi bridge | — | package config, not a pi setting; ignored if the package is removed |
| `collapseChangelog` | `true` | `false` | condensed changelog after an upgrade instead of the full screen |

**Remove:** delete each key to fall back to pi's default (or drop the whole
`compaction`/`retry` block).

### Providers & models

`models.json` + `auth.json` define **two OpenAI-compatible providers** serving the
same catalog of small self-hosted models (Qwen3-Coder-30B, Gemma 4, GLM-4.7-Flash,
gpt-oss-20b, …), all `cost: 0`:

- **`localcpp`** — LAN llama.cpp server, `http://192.168.0.204:11343/v1`, no key.
- **`duskadiy`** — remote, `https://llm.duskadiy.com/api/v1`, key `$DUSKADIY_API_KEY`.

This is the part you'd **replace**, not just delete, to point pi at your own backend:
edit `models.json` (baseUrl + model `id`s, keeping each `id` exactly matching your
server's model id and `contextWindow` matching its loaded `ctx-size`) and set the
matching credential in `auth.json`. `settings.json > enabledModels` is a glob
allowlist for the Ctrl+P picker; `defaultProvider`/`defaultModel` pick the startup
model.

> **Secret hygiene:** `$DUSKADIY_API_KEY` lives in
> `.config/fish/conf.d/secrets.fish` (gitignored) and is only *referenced* in tracked
> config. `auth.json` is **not tracked** (gitignored as of 2026-08-08): pi's interactive
> `/login` rewrites it with the **literal** key, and a tracked copy would be one stray
> `/login` away from committing a real token. Bootstrap a new host with
> `cp auth.json.example auth.json`. The key itself lives in a shell file that is *not*
> tracked and *not* stowed, so it never reaches this repo — `conf.d/secrets.fish` for
> fish, `~/.bash_profile` for bash.

---

## Replicating just one piece

- **Just the status bar:** copy `agent/extensions/statusbar.ts` into your
  `~/.pi/agent/extensions/`, re-stow/restart, `/reload`. Colors follow your active
  theme automatically. Needs a Nerd Font terminal for the glyphs.
- **Just vim input:** `pi install npm:pi-vim`, then the peer-dep install above (this
  build needs it), then `/reload`. Copy the `piVim` block from `settings.json` for the
  same colors and clipboard behaviour, and `agent/extensions/vim-toggle.ts` if you want
  `/vim` to toggle it.
- **Just plan mode:** copy `agent/extensions/plan-mode/` **and** add the
  `app.thinking.cycle` remap to your `keybindings.json` (else Shift+Tab collides).
- **Just the theme:** copy `agent/themes/catppuccin-mocha.json`, set
  `"theme": "catppuccin-mocha"`.
- **Just the slash commands:** copy `agent/prompts/commit.md` / `review.md`.

Validate any JSON edit with `jq . agent/settings.json` (there's no build/test step).
