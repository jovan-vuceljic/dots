-- Minimal HyDE on Hyprland 0.57 (Lua config).
--
-- ~/.config/hypr holds the Hyprland side only:
--   hyprland.lua      this file: env, look, input, autostart
--   binds.lua         keybinds (HyDE layout + the dots overrides); Super+/ lists them
--   rules.lua         window + layer rules
--   hyprlock.conf     your dots lock screen (+ hyprlock-host.conf sizes, hyprlock/assets, battery.sh)
--   hypridle.conf
--   hyprpaper.conf    the wallpaper (hyprpaper)
--   scripts/          osd.sh, screenshot.sh, menu.sh, wallpaper.sh, session.sh
--   wallpapers/       the default wallpaper
--
-- waybar, rofi, dunst, kitty, wayvnc and qt6ct keep their configs in their own ~/.config/<app>/.
-- Colors are a fixed Catppuccin Mocha (HyDE's values) written into each of those configs.
-- Shared values go through the `mini` global.

local home = os.getenv("HOME")
local hypr = home .. "/.config/hypr"

mini = {
	scripts = hypr .. "/scripts",
	terminal = "kitty",
	explorer = "dolphin",
	browser = "librewolf",
	editor = "nvim",
	waybar = "waybar",
	rofi = "rofi",
}

-- ── Monitors ─────────────────────────────────────────────────────────────────
-- VNC at the viewer's resolution, when there's no real monitor (a VM, vkms on a box without a
-- GPU, or a GPU with nothing plugged in; next to a real monitor the first two rules match
-- nothing): wayvnc only resizes outputs
-- named HEADLESS-*, so the session renders to a headless output (created in autostart) that
-- follows the client's window/fullscreen size, and Virtual-1 (the Proxmox console, or vkms's
-- virtual screen) mirrors it. HEADLESS-VNC
-- keeps mode "preferred": a fixed mode would snap it back on every `hyprctl reload`, and
-- scale must be pinned (auto picks 2 for a headless 1920x1080).
hl.monitor({ output = "HEADLESS-VNC", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "Virtual-1", mode = "preferred", position = "auto", scale = 1, mirror = "HEADLESS-VNC" })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- ── Environment ──────────────────────────────────────────────────────────────
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice") -- HyDE's cursor (AUR: bibata-cursor-theme-bin)
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") -- Qt style/icons/fonts + Catppuccin palette (~/.config/qt6ct)
-- KDE defaults (dolphinrc, kdeglobals) live in ~/.config/kdedefaults: read as defaults, so
-- Dolphin's own saves land in ~/.config/dolphinrc instead of the dotfiles repo
hl.env("XDG_CONFIG_DIRS", home .. "/.config/kdedefaults:/etc/xdg")

-- ── Autostart ────────────────────────────────────────────────────────────────
-- Only on session start; everything top-level below re-runs on `hyprctl reload`.
hl.on("hyprland.start", function()
	hl.exec_cmd(
		"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP && systemctl --user start hyprpolkitagent xdg-desktop-portal-hyprland"
	)
	-- In order: VNC (wayvnc reads ~/.config/wayvnc/config). With no real monitor (a *-Virtual-*
	-- DRM connector: a VM's QEMU screen or vkms on a box without a GPU; or a GPU with nothing
	-- plugged in) it gets a headless output (+ reload, so Virtual-1's mirror rule finds it) that
	-- resizes to the viewer; next to a real monitor that would be an invisible extra monitor the
	-- mouse and new windows can vanish into, so there wayvnc shares the real (first) monitor at
	-- its own resolution. Then the wallpaper
	-- (wallpaper.sh makes sure the link hyprpaper.conf reads exists) and waybar. Waybar's
	-- workspaces module comes up empty when started at login and never recovers; one reload
	-- (SIGUSR2) a few seconds later repopulates it (verified on the failing instance).
	hl.exec_cmd(
		"if ls /sys/class/drm | grep -q -- -Virtual- || ! grep -qsx connected /sys/class/drm/card*-*/status; then hyprctl output create headless HEADLESS-VNC && hyprctl reload; wayvnc -o HEADLESS-VNC & else wayvnc & fi; "
			.. mini.scripts
			.. "/wallpaper.sh; hyprpaper & "
			.. mini.waybar
			.. " & sleep 5; pkill -USR2 -x waybar"
	)
	hl.exec_cmd("dunst")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd(
		"gsettings set org.gnome.desktop.interface color-scheme prefer-dark; gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark; gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark; gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10'; gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'; gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice; gsettings set org.gnome.desktop.interface cursor-size 24"
	)
end)

-- ── Look and feel ────────────────────────────────────────────────────────────
hl.config({
	general = {
		gaps_in = 3,
		gaps_out = 8,
		border_size = 2,
		col = {
			-- Catppuccin Mocha, as HyDE's theme sets them
			active_border = { colors = { "rgba(ca9ee6ff)", "rgba(f2d5cfff)" }, angle = 45 },
			inactive_border = { colors = { "rgba(b4befecc)", "rgba(6c7086cc)" }, angle = 45 },
		},
		resize_on_border = true,
		layout = "dwindle",
	},
	decoration = {
		rounding = 10,
		shadow = { enabled = true, range = 8, render_power = 2, color = "rgba(11111b66)" },
		blur = {
			enabled = true,
			size = 6,
			passes = 2,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
			special = true,
			popups = true,
		},
	},
	animations = { enabled = true },
	dwindle = { preserve_split = true },
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		force_default_wallpaper = 0,
		focus_on_activate = true,
	},
	input = {
		kb_layout = "us",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = { natural_scroll = false },
	},
})

-- HyDE theme animation set (same curves the dots layer ports from animations/theme.conf)
hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "once" })
hl.animation({ leaf = "fade", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" })

-- ── Rules + binds ────────────────────────────────────────────────────────────
require("rules")
require("binds")
