# Start Hyprland when logging in on tty1 — at boot that's the getty autologin
# (/etc/systemd/system/getty@tty1.service.d/autologin.conf). Not over SSH, not inside a
# running session, and not in a display manager's non-interactive `fish --login -c` (SDDM
# runs one to read the environment). No `exec`: if Hyprland exits or crashes you land at
# this shell instead of an autologin → crash loop.
if status is-login; and status is-interactive; and test -z "$WAYLAND_DISPLAY"; and test "$XDG_VTNR" = 1
    start-hyprland
end
