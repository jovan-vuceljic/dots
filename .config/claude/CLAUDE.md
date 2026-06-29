# Global user preferences (applies to every project)

## Environment
- Arch Linux, Wayland, fish shell, kitty terminal. Prefer fish-compatible syntax in shell snippets (not bash-isms) when writing things the user will run interactively. Clipboard is `wl-copy`.
- Package manager: pacman / yay. Common abbrs: `pacs`, `yays`.

## Local-first LLMs
- The user self-hosts models on the LAN at `192.168.0.204`:
  - llama.cpp server — `http://192.168.0.204:11343/v1` (OpenAI-compatible).
  - Ollama — `192.168.0.204:11434`.
- Recurring models: Qwen3-Coder-30B, gemma-4-26B, DeepSeek-Coder-V2-Lite, GLM-4.7-Flash. When configuring any AI/agent tool, default to these endpoints rather than a cloud API unless asked otherwise.

## Git
- **Do not run `git commit` or `git push`, and never offer or ask to do the committing/pushing yourself** — the user reviews and commits entirely manually (these are also denied in settings.json). Stage/prepare changes and stop there. You may suggest a commit message for the user to use, but nothing more.

## Formatting
- Lua: format with `stylua` (2-space indent, 120 col, no call parentheses — see any `.stylua.toml`).

## Dotfiles
- Configs live in the dotfiles repo under `.config/` and are surfaced via per-directory symlinks into `~/.config/` (and `~/.claude/`). Editing a file under the repo's `.config/` is editing the live config — no deploy step.
