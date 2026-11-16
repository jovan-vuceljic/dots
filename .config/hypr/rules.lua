-- Window + layer rules: HyDE's float/dialog set and the dots opacity rules,
-- trimmed to what this box runs.

-- ── Layers: blur behind the bar, launcher and notifications ──────────────────
for _, ns in ipairs({ "waybar", "cavabar", "rofi", "notifications" }) do
	hl.layer_rule({ name = "blur_" .. ns, match = { namespace = ns }, blur = true, ignore_alpha = 0 })
end
hl.layer_rule({ name = "rofi_anim", match = { namespace = "rofi" }, animation = "popin 90%" })

-- ── Floats ───────────────────────────────────────────────────────────────────
hl.window_rule({
	name = "float_utils",
	match = {
		class = "^(org.pulseaudio.pavucontrol|nm-connection-editor|nm-applet|blueman-manager|hyprpolkitagent|org.kde.polkit-kde-authentication-agent-1|xdg-desktop-portal-gtk|org.freedesktop.impl.portal.desktop.gtk|org.freedesktop.impl.portal.desktop.hyprland|com.gabm.satty|qt6ct|nwg-look|org.kde.ark|virt-viewer|remote-viewer)$",
	},
	float = true,
})
hl.window_rule({
	name = "float_dialogs",
	match = { title = "^(Open File|Open Files|Save File|Save As|Open Folder|Select a File|Choose Files|File Upload|Library|Volume Control|Authentication Required)(.*)$" },
	float = true,
})
hl.window_rule({
	name = "pip",
	match = { title = "^(Picture-in-Picture|Picture in picture)$" },
	float = true,
	pin = true,
	keep_aspect_ratio = true,
})

-- ── Opacity ("active inactive fullscreen") ───────────────────────────────────
hl.window_rule({
	name = "opacity_terms",
	match = { class = "^(kitty|org.kde.dolphin|org.kde.ark|nwg-look|qt6ct)$" },
	opacity = "0.90 0.80 1",
})
hl.window_rule({
	name = "opacity_applets",
	match = { class = "^(org.pulseaudio.pavucontrol|nm-connection-editor|hyprpolkitagent)$" },
	opacity = "0.85 0.75 1",
})

-- ── Behaviour ────────────────────────────────────────────────────────────────
hl.window_rule({ name = "suppress_maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
	name = "fix_xwayland_drags",
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})
hl.window_rule({
	name = "idle_inhibit_media",
	match = { class = "^(.*mpv.*|.*vlc.*|.*librewolf.*|.*firefox.*|.*zen.*|.*chromium.*)$" },
	idle_inhibit = "fullscreen",
})
