# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

This is **not application source** — it's the on-disk configuration tree for `pi`, the TUI coding agent from [earendil-works/pi](https://github.com/earendil-works/pi) (binary at `/usr/bin/pi`, currently v0.80.2). It lives inside the user's dotfiles repo (`~/.dotfiles`) and is surfaced into `$HOME` via symlink: `~/.pi -> .dotfiles/.pi`. Editing a file here edits the live config — there is no build, deploy, or stow step to run afterward.

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

## Providers and models

Two OpenAI-compatible providers are configured, both serving the same catalog of small local/self-hosted models (Qwen3-Coder-30B, Gemma 4, DeepSeek-Coder-V2-Lite, GLM-4.7-Flash, etc.). All have `cost: 0` and `reasoning: false`:

- **`duskadiy`** — remote, `https://llm.duskadiy.com/api/v1`, key `$DUSKADIY_API_KEY`.
- **`localcpp`** — LAN llama.cpp server at `http://192.168.0.204:11343/v1`, no key.

When adding/editing a model, keep `id` exactly matching the server's model id, and set `contextWindow`/`maxTokens` to match how the model is actually loaded (note `Qwen3-Coder-30B` is deliberately capped at 8192/4096 here, unlike the others at 81920/16384).

## Secrets

`$DUSKADIY_API_KEY` is the only real secret. It is defined in `.config/fish/conf.d/secrets.fish` (gitignored) and referenced — never inlined — in tracked config. Keep it that way: tracked files (`auth.json`, `models.json`) must contain `$DUSKADIY_API_KEY`, not the literal token.

⚠️ `auth.json` is git-tracked but pi's interactive `/login` writes the **literal** key into it — don't use `/login` for `duskadiy` (or `git rm --cached auth.json` first), or a real token will land in a commit. Installed-package and runtime artifacts (`.pi/agent/npm/`, `git/`, `trust.json`, `sessions/`) are gitignored.

## Running pi

- `pi` — interactive TUI. `pi -p "<prompt>"` — non-interactive, print and exit.
- `pi -c` / `pi -r` — continue / pick a session to resume.
- `pi config` — TUI to enable/disable discovered resources. `pi --list-models [search]` — list available models.
- `--provider` / `--model` / `--thinking` override the `settings.json` defaults per-run.
- pi also auto-discovers `CLAUDE.md`/`AGENTS.md` as context files (disable with `-nc`) — i.e. pi reads this very file too, not just Claude Code.
