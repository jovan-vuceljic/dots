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
- `keybindings.json` — custom keybindings (vim-style scroll/navigation).
- `CLAUDE.md` — global user preferences applied to every project.
- `hooks/format-lua.py` — PostToolUse hook: runs `stylua` on edited `.lua` files (only where a
  `.stylua.toml` exists; no-ops if stylua isn't installed).

Paths inside `settings.json` reference `~/.claude/...` (the symlinks), so they work regardless
of where the dotfiles repo is cloned (`~/.dotfiles`, `~/.dots`, …).

## What is **not** tracked (stays local, per device)

Everything else under `~/.claude/` is machine-specific or secret and must never be committed:
credentials (`.credentials.json`), session history, `projects/` (transcripts + memory),
caches, and the `plugins/` cache/binaries.

## Setup on a new device

```sh
# 1. Clone these dotfiles and deploy with stow (creates ~/.config/claude -> the repo copy)
cd ~ && stow .dotfiles

# 2. Point Claude's default dir at the tracked copies (run once per device)
ln -sfn ~/.config/claude/settings.json     ~/.claude/settings.json
ln -sfn ~/.config/claude/statusline.py     ~/.claude/statusline.py
ln -sfn ~/.config/claude/keybindings.json  ~/.claude/keybindings.json
ln -sfn ~/.config/claude/CLAUDE.md         ~/.claude/CLAUDE.md
ln -sfn ~/.config/claude/hooks             ~/.claude/hooks

# 3. Launch Claude and log in once (credentials are NOT synced)
claude

# 4. Reinstall the plugins from settings.json -> enabledPlugins
#    (typescript-lsp, frontend-design — anthropics/claude-plugins-official) via /plugin.
#    Optional: install stylua (e.g. via nvim Mason) for the lua-format hook.
```

`~/.claude/` is created by Claude on first run; the `ln -sfn` commands replace its generated
files with links to these tracked copies.

## Adding more config later

Drop the file/dir under `.config/claude/` here and symlink it into `~/.claude/`, e.g.:

```sh
ln -sfn ~/.config/claude/commands ~/.claude/commands
ln -sfn ~/.config/claude/agents   ~/.claude/agents
```
