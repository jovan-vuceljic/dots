# ~/.dots

One flat stow package: the tree under here mirrors `$HOME`. New machine: start with
`README-fresh-install.md` (archinstall choices, packages, first boot).

```sh
cd ~/.dots && stow --no-folding .      # link (re-run after adding a file)
cd ~/.dots && stow --no-folding -D .   # unlink
```

`--no-folding` links file by file, so every directory under `~` stays a real directory.
That's what keeps the generated `theme.*` files (below) out of the repo: they land next to the
symlinked configs, never inside `~/.dots`. stow skips this README (package-root `README.*`).

Contents:

- **Shell/CLI**, from dots `common`, trimmed to what this box runs: `.bashrc`, `.inputrc`, `.pi/`, and
  in `.config/` bat, cava, claude, fish, git, lazygit, misc, nvim, pyradio, tmux (cava + pyradio for
  the Super+R music session). `~/.claude/*` links come from `~/.config/claude/link.sh`. Dropped (still
  in `~/.dots/common`): aichat, opencode, presenterm, tuios, btop, fastfetch, plus the aliases and
  fish bits that only served them.
  The `dots`/`cdots`/`keybinds` shortcuts point here now.
- **Desktop**: a minimal HyDE on Hyprland 0.57 (Lua config), described below.

## Desktop layout

| path | what |
|---|---|
| `.config/hypr/hyprland.lua` | env, look, input, autostart; loads `rules.lua` + `binds.lua` |
| `.config/hypr/.luarc.json` | lua_ls setup (Neovim) for the Hyprland Lua API: stubs, Lua 5.5, `hl`/`mini` globals |
| `.config/hypr/binds.lua` | HyDE layout + the dots overrides; every bind has a `[Group]` description (Super+/) |
| `.config/hypr/rules.lua` | floats/dialogs, opacity, blur on the waybar/rofi/notification layers |
| `.config/hypr/hyprlock.conf` | your dots lock screen, unchanged (+ `hyprlock/assets/`, `battery.sh`) |
| `.config/hypr/hyprlock-host.conf` | its font/logo sizes for 1920x1080 |
| `.config/hypr/hypridle.conf` | lock at 15 min, dpms off at 20 |
| `.config/hypr/hyprpaper.conf` | the wallpaper |
| `.config/hypr/scripts/` | `osd.sh` `screenshot.sh` `menu.sh` `wallpaper.sh` `session.sh` (headless start, see VNC) |
| `.config/hypr/wallpapers/` | the default wallpaper |
| `.config/waybar/` | `config.jsonc` + `style.css` (the dots "custom" layout, main bar + cava bar), `theme.css` (colours), `cava-waybar.sh` + `cava.width` |
| `.config/rofi/config.rasi` | HyDE-style launcher with an image side panel (the hyprlock background); every menu uses it |
| `.config/dunst/dunstrc` | notifications + the volume/brightness OSD |
| `.config/kitty/kitty.conf`, `theme.conf` | terminal; `theme.conf` = HyDE's Catppuccin Mocha kitty colours |
| `.config/wayvnc/config` | VNC on 127.0.0.1:5900 |
| `.config/gtk-3.0/gtk.css`, `.config/gtk-4.0/gtk.css` | GTK colours (Catppuccin) over `adw-gtk3-dark` / libadwaita |
| `.config/qt6ct/` | Qt look (HyDE's settings, Fusion instead of Kvantum): Catppuccin palette, Papirus, Cantarell, single-click |
| `.config/kdedefaults/` | HyDE's `dolphinrc` + `kdeglobals` as *defaults* (see below) |
| `.local/share/color-schemes/CatppuccinMocha.colors` | KDE colour scheme for Dolphin |
| `.local/share/kio/servicemenus/set-wallpaper.desktop` | Dolphin right-click on an image → Set as wallpaper |

Every app runs with its default config path (`waybar`, `rofi`, `dunst`, `kitty`), no `-c` flags.

## Colours: Catppuccin Mocha

One fixed palette, the values HyDE's own Catppuccin Mocha theme uses, written straight into each
app's config: the border gradient in `hyprland.lua`, waybar's `theme.css` (imported by `style.css`),
a `* { }` block in rofi's `config.rasi`, `dunstrc`,
kitty's `theme.conf`, the GTK `gtk.css` files, the qt6ct palette and the KDE `.colors` scheme. Nothing is generated. The one
deliberate difference from HyDE is a dark highlighted row in rofi and Dolphin instead of light lavender.

## Wallpaper: hyprpaper

`~/.config/hypr/hyprpaper.conf` reads `~/.local/state/hypr/wallpaper`, a link to the chosen image
(outside the repo, so the choice survives logins without touching git). Change it with
`~/.config/hypr/scripts/wallpaper.sh <image>` or Dolphin's right-click → Set as wallpaper. On a fresh
box the link points at `.config/hypr/wallpapers/foss_wallpaper_edit.png`.

## Dolphin, HyDE-style

No menubar, statusbar or selection toggles, an icon-only 16 px toolbar, previews, single-click open,
kitty as "Open Terminal Here", and Papirus icons. Catppuccin colours come from qt6ct's palette for
Qt apps, plus a KDE colour scheme (`CatppuccinMocha.colors`) that `kdeglobals` selects, since KDE apps
ignore qt6ct's palette and fall back to light Breeze without one.
`dolphinrc` and `kdeglobals` sit in `~/.config/kdedefaults`, which `hyprland.lua` puts on
`XDG_CONFIG_DIRS`. KDE reads them as defaults and writes its own state (window size, view
choices) to `~/.config/dolphinrc`, outside the repo. A setting changed in Dolphin's UI overrides
the default there.

## Starting

At boot, the tty1 autologin (`/etc/systemd/system/getty@tty1.service.d/autologin.conf`, outside
this repo) logs `anon` in, and `.config/fish/conf.d/hyprland.fish` runs `start-hyprland` on tty1
logins. Quitting Hyprland drops you to that tty1 shell. To undo the autologin:
`sudo rm -r /etc/systemd/system/getty@tty1.service.d`.

## VNC

Autostart starts wayvnc in every session, listening on `127.0.0.1:5900`
(`.config/wayvnc/config`), so you reach it through an SSH tunnel.

**With no real monitor: at the client's resolution.** That's a VM, a box with no GPU running vkms
(below), or a GPU with nothing plugged in: autostart checks `/sys/class/drm` for a `*-Virtual-*`
screen or for no connected monitor. wayvnc only resizes outputs named `HEADLESS-*`, never a real
or virtual screen. So autostart creates a headless output, wayvnc captures it
(`wayvnc -o HEADLESS-VNC`), and `Virtual-1` (a VM's console, or vkms's screen) mirrors it. When
the viewer asks for a size (TigerVNC: window resize or fullscreen, `RemoteResize` is on by default), wayvnc resizes
`HEADLESS-VNC` to match, and it stays that size across `hyprctl reload`. From the client:

```sh
ssh -L 5900:127.0.0.1:5900 anon@<box>
vncviewer -FullScreen localhost:5900
```

TigerVNC only asks for a new size when its window changes size. A windowed viewer that opens
bigger than your screen stays oversized until you resize or maximize it once. Fullscreen fits
right away.

**With a real GPU and monitor** there's no headless output: wayvnc shares the real monitor at its
own resolution, and the viewer scales it. Same tunnel, with that box's address:
`ssh -L 5900:127.0.0.1:5900 anon@<box>`, then `vncviewer localhost:5900`.

**Monitor unplugged after login:** wayvnc was sharing it, so it has no screen left and exits. Give the running session a virtual monitor and start wayvnc on it, over SSH on that box:

```sh
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -1)   # newest session
hyprctl output create headless HEADLESS-VNC                # the virtual monitor, scale 1
hyprctl dispatch 'hl.dsp.exec_cmd("wayvnc -o HEADLESS-VNC")'   # run by Hyprland, in the session
```

Then tunnel and connect as above; the virtual monitor resizes to the viewer. Back to the real
screen: `hyprctl output remove HEADLESS-VNC; pkill -x wayvnc; hyprctl dispatch
'hl.dsp.exec_cmd("wayvnc")'`. Check with `pgrep -a wayvnc` and `ss -ltn | grep 5900`.

**Nobody at the box** (no monitor, or no GPU at all): there's no screen to log in on, so start the
session over SSH on that box:

```sh
sudo ~/.config/hypr/scripts/session.sh        # login session on tty7 (+ vkms if no GPU)
sudo ~/.config/hypr/scripts/session.sh stop   # end it
```

With no GPU it first loads vkms, a virtual screen. Either way autostart sees no real monitor and
sets up VNC as above; tunnel and connect. Nothing starts at boot: run it again after every reboot.
Without a GPU the CPU draws everything (Mesa's software renderer), so it's slow.

## Keys (Super+/ shows all of them)

| combo | action |
|---|---|
| Super+T / Ctrl+Alt+T | kitty |
| Super+E | dolphin |
| Super+B | librewolf |
| Super+C | nvim in kitty |
| Super+A / Super+Tab / Super+Shift+E | rofi apps / windows / files |
| Super+V / Super+Shift+V | clipboard history / delete entry |
| Super+Q, Alt+F4 | close |
| Super+W | float · Super+Shift+F pin · Shift+F11 or Alt+Return fullscreen |
| Super+J | toggle split · Super+Shift+G group |
| Super+L | lock · Ctrl+Alt+Del power menu |
| Super+P / Super+Alt+P / Print | screenshot area / monitor / all → satty |
| Super+Alt+G | game mode (press again = reload) |
| Ctrl+Alt+W or Super+Shift+W | toggle waybar (over VNC from KDE only Super+Shift+W arrives) · Super+Shift+R reload hyprland + waybar (fullscreen viewer: windowed, KDE Spectacle takes it) |
| Super+1..0 | workspace (r~N, monitor-relative) · +Shift/+Ctrl move · +Alt move silently |
| Super+←/→, Super+Ctrl+Shift+←/→/H/L | workspace prev/next |
| Super+↑/↓, Alt+Ctrl+arrows/hjkl | focus |
| Super+Shift+arrows/hjkl | resize · Super+Alt+arrows/hjkl move (nudge float / swap tiled) |
| Super+S / Super+Shift+S | scratchpad toggle / send |

There's no Super+Delete instant exit, same as the dots layer. Logout is in the power menu.

## Packages (official repos, except the cursor)

```
hyprland waybar rofi dunst kitty dolphin hyprpolkitagent xdg-desktop-portal-hyprland
hyprlock hypridle hyprpaper cliphist wl-clipboard grim slurp satty
brightnessctl playerctl pavucontrol network-manager-applet libnotify jq stow wayvnc qt6ct kio-extras
adw-gtk-theme                                      # GTK3 look matching libadwaita, dark variant
ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji papirus-icon-theme
adobe-source-code-pro-fonts cantarell-fonts        # hyprlock.conf's fonts
librewolf
lua-language-server vscode-css-languageserver vscode-html-languageserver   # Neovim LSP
typescript-language-server eslint-language-server
```

AUR: `bibata-cursor-theme-bin` (Bibata-Modern-Ice, HyDE's cursor; set in `hyprland.lua`).

## Caveats

- The headless output + wayvnc + mirror setup exists for boxes driven over VNC. Autostart only
  creates it when there's no real monitor (a VM, vkms without a GPU, nothing plugged in); with one it runs plain
  `wayvnc` on it, and the `HEADLESS-VNC` and `Virtual-1` monitor rules match nothing, so the same
  repo works there unchanged.
- Real hardware from archinstall's Hyprland profile: it installs only `hyprland dunst kitty uwsm
  dolphin wofi xdg-desktop-portal-hyprland qt5/6-wayland polkit-kde-agent grim slurp` (and SDDM).
  Install the package list above too: this config turns off Hyprland's own wallpaper and logo, so
  without hyprpaper and waybar the session is a plain black screen (Super+T still opens kitty).
- hyprlock's greeting line reads `~/.config/fish/greet.txt`, which a weather cronjob fills on the
  other hosts. It isn't there on these boxes, so that line stays empty.
- hyprlock unlocks on `SIGUSR1`, but only after a few seconds.
