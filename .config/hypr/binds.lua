-- Keybinds: HyDE's default layout with the dots overrides folded in (dots wins
-- where both bind a combo — same policy as gui/.config/hypr/dots_binds.lua).
-- Every bind carries a "[Group] text" description; Super+/ (menu.sh keys) lists them.

local MOD = "SUPER"
local S = mini.scripts
local rofi = mini.rofi

local function bind(keys, action, desc, opts)
	opts = opts or {}
	opts.description = desc
	hl.bind(keys, type(action) == "string" and hl.dsp.exec_cmd(action) or action, opts)
end

-- ── Window management ────────────────────────────────────────────────────────
bind(MOD .. " + Q", hl.dsp.window.close(), "[Window] close focused window")
bind("ALT + F4", hl.dsp.window.close(), "[Window] close focused window")
bind(MOD .. " + W", hl.dsp.window.float({ action = "toggle" }), "[Window] toggle floating")
bind(MOD .. " + SHIFT + G", hl.dsp.group.toggle(), "[Window] toggle group")
bind("SHIFT + F11", hl.dsp.window.fullscreen(), "[Window] toggle fullscreen")
bind("ALT + RETURN", hl.dsp.window.fullscreen(), "[Window] toggle fullscreen")
bind(MOD .. " + SHIFT + F", hl.dsp.window.pin(), "[Window] pin (show on every workspace)")
bind(MOD .. " + J", hl.dsp.layout("togglesplit"), "[Window] toggle split")
bind(MOD .. " + L", "hyprlock", "[Session] lock screen")
bind("CTRL + ALT + DELETE", S .. "/menu.sh power", "[Session] power menu")
bind("CTRL + ALT + W", "pkill -x waybar || " .. mini.waybar, "[Session] toggle waybar")
bind(MOD .. " + SHIFT + W", "pkill -x waybar || " .. mini.waybar, "[Session] toggle waybar") -- Ctrl+Alt+W loses its W over VNC from KDE
bind(
	MOD .. " + SHIFT + R",
	"hyprctl reload; pkill -x waybar; " .. mini.waybar,
	"[Session] reload hyprland + waybar"
)

-- Game mode: kill animations/blur/gaps; pressing again reloads the config, which
-- puts every value back. Reads live state, so it survives a reload in between.
bind(MOD .. " + ALT + G", function()
	if hl.get_config("animations.enabled") then
		hl.config({
			animations = { enabled = false },
			decoration = { rounding = 0, blur = { enabled = false }, shadow = { enabled = false } },
			general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
		})
		hl.exec_cmd("notify-send -a osd -i input-gaming 'Game mode' 'on — Super+Alt+G again to restore'")
	else
		hl.dispatch(hl.dsp.reload_config())
	end
end, "[Session] toggle game mode")

-- ── Launchers ────────────────────────────────────────────────────────────────
bind(MOD .. " + T", mini.terminal, "[Launch] terminal")
bind("CTRL + ALT + T", mini.terminal, "[Launch] terminal")
bind(MOD .. " + E", mini.explorer, "[Launch] file explorer")
bind(MOD .. " + B", mini.browser, "[Launch] browser")
bind(MOD .. " + C", mini.terminal .. " " .. mini.editor, "[Launch] neovim")
bind(MOD .. " + R", mini.terminal .. " --session ~/.config/kitty/music.conf", "[Launch] music session (cava, pyradio)")
bind(MOD .. " + A", "pkill -x rofi || " .. rofi .. " -show drun", "[Launch] app launcher")
bind(MOD .. " + TAB", "pkill -x rofi || " .. rofi .. " -show window", "[Launch] window switcher")
bind(MOD .. " + SHIFT + E", "pkill -x rofi || " .. rofi .. " -show filebrowser", "[Launch] file finder")
bind(MOD .. " + slash", S .. "/menu.sh keys", "[Launch] keybind hints")
bind(MOD .. " + V", S .. "/menu.sh clip", "[Launch] clipboard history")
bind(MOD .. " + SHIFT + V", S .. "/menu.sh clip-del", "[Launch] clipboard: delete entry")

-- ── Screenshots ──────────────────────────────────────────────────────────────
bind(MOD .. " + P", S .. "/screenshot.sh area", "[Screenshot] area → satty")
bind(MOD .. " + ALT + P", S .. "/screenshot.sh output", "[Screenshot] focused monitor → satty")
bind("Print", S .. "/screenshot.sh screen", "[Screenshot] all monitors → satty")

-- ── Hardware keys (OSD through dunst) ────────────────────────────────────────
local hw = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume", S .. "/osd.sh vol up", "[Media] volume up", hw)
bind("XF86AudioLowerVolume", S .. "/osd.sh vol down", "[Media] volume down", hw)
bind("XF86AudioMute", S .. "/osd.sh vol mute", "[Media] mute output", { locked = true })
bind("XF86AudioMicMute", S .. "/osd.sh mic", "[Media] mute microphone", { locked = true })
bind("XF86MonBrightnessUp", S .. "/osd.sh bri up", "[Media] brightness up", hw)
bind("XF86MonBrightnessDown", S .. "/osd.sh bri down", "[Media] brightness down", hw)
bind("XF86AudioPlay", "playerctl play-pause", "[Media] play / pause", { locked = true })
bind("XF86AudioPause", "playerctl play-pause", "[Media] play / pause", { locked = true })
bind("XF86AudioNext", "playerctl next", "[Media] next track", { locked = true })
bind("XF86AudioPrev", "playerctl previous", "[Media] previous track", { locked = true })

-- ── Focus ────────────────────────────────────────────────────────────────────
bind(MOD .. " + UP", hl.dsp.focus({ direction = "up" }), "[Focus] up")
bind(MOD .. " + DOWN", hl.dsp.focus({ direction = "down" }), "[Focus] down")
bind(MOD .. " + CTRL + UP", hl.dsp.focus({ direction = "up" }), "[Focus] up")
bind(MOD .. " + CTRL + DOWN", hl.dsp.focus({ direction = "down" }), "[Focus] down")
for dir, keys in pairs({ left = { "LEFT", "H" }, right = { "RIGHT", "L" }, up = { "UP", "K" }, down = { "DOWN", "J" } }) do
	for _, key in ipairs(keys) do
		bind("ALT + CTRL + " .. key, hl.dsp.focus({ direction = dir }), "[Focus] " .. dir)
	end
end
bind("ALT + TAB", hl.dsp.focus({ direction = "down" }), "[Focus] down")
-- Super+Ctrl+H/L: cycle the group (no-op outside one) and move focus, as in dots
bind(MOD .. " + CTRL + H", function()
	hl.dispatch(hl.dsp.group.prev())
	hl.dispatch(hl.dsp.focus({ direction = "left" }))
end, "[Focus] group prev + left")
bind(MOD .. " + CTRL + L", function()
	hl.dispatch(hl.dsp.group.next())
	hl.dispatch(hl.dsp.focus({ direction = "right" }))
end, "[Focus] group next + right")
bind(MOD .. " + CTRL + K", hl.dsp.focus({ direction = "up" }), "[Focus] up")
bind(MOD .. " + CTRL + J", hl.dsp.focus({ direction = "down" }), "[Focus] down")

-- ── Resize (Super+Shift + arrows/hjkl) ───────────────────────────────────────
for _, m in ipairs({
	{ "RIGHT", 30, 0 },
	{ "LEFT", -30, 0 },
	{ "UP", 0, -30 },
	{ "DOWN", 0, 30 },
	{ "L", 30, 0 },
	{ "H", -30, 0 },
	{ "K", 0, -30 },
	{ "J", 0, 30 },
}) do
	bind(
		MOD .. " + SHIFT + " .. m[1],
		hl.dsp.window.resize({ x = m[2], y = m[3], relative = true }),
		"[Window] resize",
		{ repeating = true }
	)
end

-- ── Move window (Super+Alt): nudge when floating, swap when tiled ────────────
local function move_window(dx, dy, dir)
	return function()
		local w = hl.get_active_window()
		if w and w.floating then
			hl.dispatch(hl.dsp.window.move({ x = dx * 30, y = dy * 30, relative = true }))
		else
			hl.dispatch(hl.dsp.window.swap({ direction = dir }))
		end
	end
end
for _, m in ipairs({
	{ "LEFT", -1, 0, "left" },
	{ "RIGHT", 1, 0, "right" },
	{ "UP", 0, -1, "up" },
	{ "DOWN", 0, 1, "down" },
	{ "H", -1, 0, "left" },
	{ "L", 1, 0, "right" },
	{ "K", 0, -1, "up" },
	{ "J", 0, 1, "down" },
}) do
	bind(MOD .. " + ALT + " .. m[1], move_window(m[2], m[3], m[4]), "[Window] move " .. m[4], { repeating = true })
end

-- ── Mouse ────────────────────────────────────────────────────────────────────
hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "[Window] drag" })
hl.bind(MOD .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "[Window] drag-resize" })
bind(MOD .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "[Workspace] next (scroll)")
bind(MOD .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), "[Workspace] previous (scroll)")

-- ── Workspaces ───────────────────────────────────────────────────────────────
-- Pin each workspace NAME to a physical monitor so the two extended screens
-- never share a name. r~N ("Nth workspace of the FOCUSED monitor") then lands
-- on the right set: 1..10 on the Dell, 11..20 on the Samsung. This is the
-- mechanism that makes per-monitor Super+num work: hl.get_active_monitor()
-- tracks window focus, not the physical monitor, so it must NOT be used here.
for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2", default = (i == 1) })
	hl.workspace_rule({ workspace = tostring(i + 10), monitor = "HDMI-A-2", default = (i == 1) })
end

-- r~N = Nth workspace of the focused monitor (monitor-relative).
for i = 1, 10 do
	local key = (i == 10) and 0 or i
	bind(MOD .. " + " .. key, hl.dsp.focus({ workspace = "r~" .. i }), "[Workspace] go to workspace " .. i .. " (this monitor)")
	bind(MOD .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = "r~" .. i }), "[Workspace] move window to workspace " .. i .. " (this monitor)")
	bind(MOD .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = "r~" .. i }), "[Workspace] move window to workspace " .. i .. " (this monitor)")
	bind(
		MOD .. " + ALT + " .. key,
		hl.dsp.window.move({ workspace = "r~" .. i, follow = false }),
		"[Workspace] move window to workspace " .. i .. " (this monitor) silently"
	)
end
bind(MOD .. " + RIGHT", hl.dsp.focus({ workspace = "r+1" }), "[Workspace] next")
bind(MOD .. " + LEFT", hl.dsp.focus({ workspace = "r-1" }), "[Workspace] previous")
bind(MOD .. " + CTRL + SHIFT + RIGHT", hl.dsp.focus({ workspace = "r+1" }), "[Workspace] next")
bind(MOD .. " + CTRL + SHIFT + LEFT", hl.dsp.focus({ workspace = "r-1" }), "[Workspace] previous")
bind(MOD .. " + CTRL + SHIFT + L", hl.dsp.focus({ workspace = "r+1" }), "[Workspace] next")
bind(MOD .. " + CTRL + SHIFT + H", hl.dsp.focus({ workspace = "r-1" }), "[Workspace] previous")
bind(MOD .. " + CTRL + RIGHT", hl.dsp.window.move({ workspace = "r+1" }), "[Workspace] move window to next")
bind(MOD .. " + CTRL + LEFT", hl.dsp.window.move({ workspace = "r-1" }), "[Workspace] move window to previous")
bind(MOD .. " + CTRL + ALT + L", hl.dsp.window.move({ workspace = "r+1" }), "[Workspace] move window to next")
bind(MOD .. " + CTRL + ALT + H", hl.dsp.window.move({ workspace = "r-1" }), "[Workspace] move window to previous")
bind(MOD .. " + CTRL + E", hl.dsp.focus({ workspace = "empty" }), "[Workspace] nearest empty")

-- Scratchpad
bind(MOD .. " + S", hl.dsp.workspace.toggle_special("magic"), "[Workspace] toggle scratchpad")
bind(MOD .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), "[Workspace] move window to scratchpad")
bind(
	MOD .. " + ALT + S",
	hl.dsp.window.move({ workspace = "special:magic", follow = false }),
	"[Workspace] move window to scratchpad silently"
)
