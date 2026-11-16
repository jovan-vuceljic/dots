#!/usr/bin/env bash
# menu.sh power | clip | clip-del | clip-wipe | keys — the rofi menus
menu() { rofi -dmenu -i -no-show-icons "$@"; } # look: ~/.config/rofi/config.rasi

pkill -x rofi && exit 0 # the same bind again closes an open menu

case ${1:-} in
power)
	choice=$(printf '%s\n' "󰌾  Lock" "󰍃  Logout" "󰒲  Suspend" "󰜉  Reboot" "󰐥  Shutdown" |
		menu -p power -theme-str 'listview { lines: 5; }') || exit 0
	case $choice in
	*Lock) pidof hyprlock || hyprlock ;;
	*Logout) hyprctl dispatch 'hl.dsp.exit()' ;; # Lua mode: dispatch takes a Lua expression
	*Suspend) systemctl suspend ;;
	*Reboot) systemctl reboot ;;
	*Shutdown) systemctl poweroff ;;
	esac
	;;
clip)
	sel=$(cliphist list | menu -p clipboard -display-columns 2 -display-column-separator '\t') || exit 0
	printf '%s' "$sel" | cliphist decode | wl-copy
	;;
clip-del)
	sel=$(cliphist list | menu -p delete -display-columns 2 -display-column-separator '\t') || exit 0
	printf '%s' "$sel" | cliphist delete
	;;
clip-wipe) cliphist wipe && notify-send -a clipboard "Clipboard" "history wiped" ;;
keys)
	# every bind that carries a description, as "combo  [group] text", grouped
	hyprctl binds -j | jq -r '
		.[] | select(.has_description) | .modmask as $m
		| ([ (if ($m / 64 | floor) % 2 == 1 then "Super" else empty end),
		     (if ($m / 4  | floor) % 2 == 1 then "Ctrl"  else empty end),
		     (if ($m / 8  | floor) % 2 == 1 then "Alt"   else empty end),
		     (if $m % 2 == 1 then "Shift" else empty end) ] + [ .key ] | join(" + ")) as $combo
		| "\(.description)\t\($combo)"' |
		sort -u | awk -F'\t' '{ printf "%-34s %s\n", $2, $1 }' |
		menu -p keybinds -theme-str 'window { width: 900px; }' >/dev/null
	;;
*) echo "usage: menu.sh power|clip|clip-del|clip-wipe|keys" >&2; exit 1 ;;
esac
