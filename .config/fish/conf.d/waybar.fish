## gui package — waybar helpers. Lives in conf.d/ (fish sources every conf.d/*.fish),
## NOT in host.fish: each host package ships its own host.fish, which stow deploys last
## with --override — a gui/host.fish would be shadowed on every host that has one.

# Reload the custom waybar (kill + relaunch, detached so it survives this shell).
# Same invocation as userprefs.conf exec-once / the Ctrl+Alt+W bind. Killing waybar
# also stops its cava child (cava-waybar.sh is a child of the bar).
abbr wbar 'killall waybar; setsid -f waybar -c ~/.config/waybar/layouts/custom.jsonc -s ~/.config/waybar/layouts/custom.css'
