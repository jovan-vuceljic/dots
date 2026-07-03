# Claude Code config

Portable [Claude Code](https://claude.com/claude-code) customizations, synced via these
dotfiles. Claude Code still uses its default `~/.claude/` directory; we surface the tracked
files below into it via per-file/dir symlinks, so edits made through Claude write straight
back into this repo.

## What's tracked here

- `settings.json` — global settings: permissions (deny git commit/push + read of secret
  files), default `model`, `enabledPlugins`, vim mode, dark theme, `effortLevel`, fullscreen
  TUI, `statusLine`, `hooks`, `worktree` defaults, …
- `statusline.py` — rich status line (dir, git, model, context %, cost, RAM/CPU/temp/disk).
  See [StatusBar.md](StatusBar.md) for what each segment and colour means.
- `keybindings.json` — custom keybindings (vim-style scroll/navigation).
- `CLAUDE.md` — global user preferences applied to every project.
- `hooks/format.py` — PostToolUse hook: formats edited files by extension (stylua / ruff /
  prettier / gofmt / rustfmt / fish_indent / shfmt / taplo). Opinionated formatters (stylua, ruff,
  prettier, taplo) only run where the project opts in via a config file found walking up; canonical
  ones (gofmt, rustfmt, fish_indent, shfmt) run on sight. No-ops if the formatter isn't installed,
  and always exits 0.
- `skills/` — custom [Agent Skills](https://code.claude.com/docs/en/skills). See **Skills** below.
- `link.sh` — idempotent bootstrap that creates the `~/.claude` symlinks below.

Paths inside `settings.json` reference `~/.claude/...` via `$HOME`/`PATH` (`/usr/bin/env
python3 ~/.claude/...`), so they work regardless of the username, python location, or where the
dotfiles repo is cloned (`~/.dotfiles`, `~/.dots`, …).

## What is **not** tracked (stays local, per device)

Everything else under `~/.claude/` is machine-specific or secret and must never be committed:
credentials (`.credentials.json`), session history, `projects/` (transcripts + memory),
caches, and the `plugins/` cache/binaries.

## Setup on a new device

```sh
# 1. Clone these dotfiles and deploy with stow (creates ~/.config/claude -> the repo copy)
cd ~ && stow .dotfiles

# 2. Point Claude's default dir at the tracked copies (run once; safe to re-run)
bash ~/.config/claude/link.sh

# 3. Launch Claude and log in once (credentials are NOT synced)
claude

# 4. Reinstall the plugins from settings.json -> enabledPlugins
#    (typescript-lsp, frontend-design — anthropics/claude-plugins-official) via /plugin.
#    Optional: install any formatters you want the hook to use (stylua, ruff, prettier, …).
```

`~/.claude/` is created by Claude on first run; `link.sh` replaces its generated files with
links to these tracked copies. Re-run it any time a link gets clobbered.

## Skills

Custom skills live in `skills/<name>/SKILL.md` (the directory name is the `/command`) and are
linked in as `~/.claude/skills`. All are `disable-model-invocation: true` — explicit `/` only,
so Claude never auto-triggers them. Run them inside the repo whose branch you're working on.

- **`/review-branch [base]`** — reviews the current branch's diff (vs its merge-base with the
  base branch) for 🐞 bugs / 🔒 security / ⚡ optimizations / 📖 readability, reports grouped
  findings with `file:line`, then applies the readability + safe fixes *after you approve*. Never
  commits.
  Borrows `/code-review`'s discipline: CLAUDE.md-aware, changed-lines-only, verified bugs with a
  false-positive filter (skips what linters/CI catch and pre-existing issues). Ends by pointing
  you at the relevant built-in follow-ups (`/security-review`, `/code-review`, `/verify`, …).
- **`/pr-description [base]`** — auto-detects this repo's GitHub PR template
  (`.github/pull_request_template.md`, …), fills it from the branch diff + commits, prints a
  copy-paste markdown block, and copies it to the clipboard with `wl-copy`. Leaves verification
  checkboxes for you; never creates/pushes the PR.
- **`/commit-msg [hint]`** — reads the **staged** diff, infers the repo's commit style from recent
  `git log` (e.g. this repo's `[Scope] summary`), drafts a matching message, prints it, and copies
  it to the clipboard with `wl-copy`. Never stages or commits — draft only.
- **`/pr-loop [pr]`** — babysits the current branch's PR in a self-paced loop: fixes review
  comments that don't need your input — from **any** reviewer (Codex, Claude, humans) plus any
  `@claude` request — `git add`s them, drafts the commit message (`/commit-msg` style) and replies
  on the threads, then pings you to commit & push and re-checks every ~10 min (via
  `ScheduleWakeup`). Resolves threads once their fix is pushed. Stops when no unresolved comments
  remain or the automated reviewers (Codex/Claude) hit their limit. Prep-only — never
  commits/pushes/merges; needs `gh` authed and the session left open. Each cycle it prints when it
  will re-check and that `Esc` (between cycles) stops it; on the last cycle it prints a clear
  **"Finished — no more active issues"** and does not reschedule.

## Adding more config later

Drop the file/dir under `.config/claude/` here, add its name to the `items` list in `link.sh`,
and re-run `bash ~/.config/claude/link.sh`. For example `commands/` or `agents/`.
