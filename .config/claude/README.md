# Claude Code config

Portable [Claude Code](https://claude.com/claude-code) customizations, synced via these
dotfiles. Claude Code still uses its default `~/.claude/` directory for everything; we only
point its two portable config files at the copies tracked here.

## What's tracked here

- `settings.json` — global settings (permissions, `enabledPlugins`, vim mode, dark theme,
  `effortLevel`, fullscreen TUI, statusLine command, …).
- `statusline-command.sh` — custom status line (cwd, git branch, model, context %).

## What is **not** tracked (stays local, per device)

Everything else under `~/.claude/` is machine-specific or secret and must never be committed:
credentials (`.credentials.json`), session history, `projects/` (transcripts + memory),
caches, and the `plugins/` cache/binaries.

## Setup on a new device

```sh
# 1. Clone these dotfiles to ~/.dotfiles and deploy with stow
cd ~ && stow .dotfiles          # creates ~/.config/claude -> ../.dotfiles/.config/claude

# 2. Point Claude's default config dir at the tracked copies (run once)
ln -sf ~/.config/claude/settings.json          ~/.claude/settings.json
ln -sf ~/.config/claude/statusline-command.sh  ~/.claude/statusline-command.sh

# 3. Launch Claude and log in once (credentials are NOT synced)
claude

# 4. Reinstall plugins listed in settings.json -> enabledPlugins
#    (typescript-lsp, frontend-design from the anthropics/claude-plugins-official marketplace)
#    via the /plugin command inside Claude Code.
```

`~/.claude/` is created by Claude on first run; the `ln -sf` above replaces its generated
`settings.json` / `statusline-command.sh` with links to these tracked copies. Edits made later
through Claude write straight back into this repo.

## Adding more config later

To sync additional items (e.g. custom slash commands or agents), drop them under
`.config/claude/` here and symlink them into `~/.claude/`:

```sh
ln -sf ~/.config/claude/commands ~/.claude/commands
ln -sf ~/.config/claude/agents   ~/.claude/agents
```
