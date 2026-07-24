# dotfiles

Arch + Hyprland. Managed with `gnu stow` — per-directory symlinks into `~` / `~/.config`.

Base: [HyDE](https://github.com/HyDE-Project/HyDE) — `hypr`, `waybar` and `fish` started there, edited since.
HyDE's script library lives outside this repo at `~/.local/lib/hyde/`.

## notable

- `nvim` — [NvChad](https://nvchad.com/) custom conf (base46 `onedark`)
- `waybar` — two bars in one config: the main bar + `cavabar`, a full-width cava
  visualizer layered behind it (blur via hyprland `layerrule`). The top-level
  `config.jsonc`/`style.css` are hand-maintained; HyDE's `wbarconfgen.sh` would
  regenerate them from `modules/` + `config.ctl`, so avoid the layout switcher.
- `kitty` — cursor trail + session files: `kitty --session ~/.config/kitty/{c2,music,runners}.conf`
- `alacritty` — synthwave palette in `theme.toml`, font/padding matched to kitty
- `fish` — custom prompt in `functions/`, aliases + abbrs in `config.fish`
  (mirrored into `.bashrc` as plain aliases)
- `.bashrc` — powerline prompt (muted synthwave), fish alias parity, `h <cmd>` for
  colorized `--help`
- `.inputrc` — vi mode with emacs binds kept in insert mode (`vi-insert` keymap)
- `bat` — custom themes in `bat/themes/` (NvChad `onedark`, `synthwave84`);
  run `bat cache --build` after editing them. Theme is set in `bat/config` only —
  don't export `BAT_THEME`.
