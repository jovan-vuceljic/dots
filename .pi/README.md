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
| `agent/auth.json` | provider → credential map (references like `$DUSKADIY_API_KEY`, never literals) |
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
| `vim-editor.ts` | Modal (vim-like) input editor with `[I]/[N]/[V]` indicator, hjkl/word/line motions, counts, yank/paste via the kill-ring | **local fork** of pi's bundled `examples/extensions/modal-editor.ts` | delete file → default editor; or `/vim` to toggle |
| `plan-mode/` | Read-only "plan" mode (disables edit/write, restricts bash) bound to **Shift+Tab**; `/plan` toggles, `--plan` starts in it | **vendored** copy of pi's bundled `examples/extensions/plan-mode/`, rebound from upstream `Ctrl+Alt+P` | delete the folder **and** revert the `keybindings.json` `app.thinking.cycle` remap (see below) |
| `notify.ts` | Native terminal notification (OSC 777/99, Windows toast) when the agent goes idle | **verbatim** from pi's `examples/extensions/notify.ts` | delete file |
| `questionnaire.ts` | Interactive multi-question overlay the model can call as a tool | **near-verbatim** from pi's `examples/extensions/questionnaire.ts` (one-line fix) | delete file |

> The bundled examples live at `/opt/pi-coding-agent/examples/extensions/` — that's
> where `notify`/`questionnaire`/`modal-editor`/`plan-mode` came from, and where to
> re-pull the two forks after a pi upgrade before re-applying the local edits (the
> forks' own headers document those edits).

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
`/opt/pi-coding-agent/docs/keybindings.md`.

```jsonc
{
  "app.thinking.cycle":   ["ctrl+shift+t"], // moved OFF Shift+Tab so plan-mode can bind it
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
| `compaction.reserveTokens` | `6144` | 16384 | small local windows (24k–128k) — don't let the response reserve dominate a short window |
| `compaction.keepRecentTokens` | `6000` | 20000 | keep less verbatim so short windows don't thrash into repeated compaction |
| `npmCommand` | `fnm exec --using=22 -- npm` | `npm` | pin extension npm installs to Node 22 via fnm |
| `retry` / `httpIdleTimeoutMs` | long (1h provider timeout, 10m idle) | shorter | local models can be slow to first token |
| `defaultThinkingLevel` | `off` | — | most local models here are non-reasoning |

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
> config. `auth.json` is git-tracked, but pi's interactive `/login` writes the
> **literal** key into it — don't `/login` for `duskadiy` or a real token lands in a
> commit. For bash its `.bash_profile` since it's not tracked by git, stow not applied.

---

## Replicating just one piece

- **Just the status bar:** copy `agent/extensions/statusbar.ts` into your
  `~/.pi/agent/extensions/`, re-stow/restart, `/reload`. Colors follow your active
  theme automatically. Needs a Nerd Font terminal for the glyphs.
- **Just vim input:** copy `agent/extensions/vim-editor.ts`, `/reload`, `/vim`.
- **Just plan mode:** copy `agent/extensions/plan-mode/` **and** add the
  `app.thinking.cycle` remap to your `keybindings.json` (else Shift+Tab collides).
- **Just the theme:** copy `agent/themes/catppuccin-mocha.json`, set
  `"theme": "catppuccin-mocha"`.
- **Just the slash commands:** copy `agent/prompts/commit.md` / `review.md`.

Validate any JSON edit with `jq . agent/settings.json` (there's no build/test step).
