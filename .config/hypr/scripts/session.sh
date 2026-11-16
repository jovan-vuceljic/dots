#!/bin/sh
# sudo session.sh       — start Hyprland over SSH on a box nobody is sitting at (headless, VNC):
#                         a real login session on tty7, the same as logging in at the console.
# sudo session.sh stop  — end it.
# No display device at all (no GPU) → loads vkms, a virtual screen; autostart then sets up VNC the
# way it does in the VM. Nothing is enabled at boot: after a reboot, run this again.
[ "$(id -u)" = 0 ] || { echo "run it with sudo" >&2; exit 1; }
user=${SUDO_USER:?run it with sudo from your own user}

if [ "$1" = stop ]; then
	systemctl stop hypr-vnc
	exit
fi
systemctl -q is-active hypr-vnc && { echo "already running"; exit 0; }
ls /sys/class/drm | grep -q '^card' || modprobe vkms

# CapabilityBoundingSet: systemd gives sessions it starts CAP_WAKE_ALARM, which locks the
# session's processes away from the same user's other processes; the settings portal then refuses
# GTK apps (default light theme, wrong font), so leave it out.
systemd-run --unit=hypr-vnc --description="Hyprland session (VNC)" \
	--uid="$user" --gid="$(id -gn "$user")" -p PAMName=login -p WorkingDirectory=~ \
	-p TTYPath=/dev/tty7 -p TTYReset=yes -p TTYVHangup=yes -p StandardInput=tty-fail \
	-p UtmpIdentifier=tty7 -p UtmpMode=user -p CapabilityBoundingSet=~CAP_WAKE_ALARM \
	-E XDG_SESSION_TYPE=wayland -E XDG_SESSION_DESKTOP=Hyprland -E XDG_CURRENT_DESKTOP=Hyprland \
	/usr/bin/start-hyprland || exit
chvt 7
echo "started: VNC on 127.0.0.1:5900 in a few seconds (ssh -L 5900:127.0.0.1:5900 $user@$(cat /etc/hostname))"
