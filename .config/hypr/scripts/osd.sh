#!/usr/bin/env bash
# osd.sh vol up|down|mute · mic · bri up|down — change it, then flash a dunst
# progress-bar OSD

osd() { # tag value icon title
	notify-send -a osd -h string:x-dunst-stack-tag:"$1" -h int:value:"$2" -i "$3" "$4" "$2%"
}

vol_of() { # sink|source → "<pct> <muted 0|1>"
	wpctl get-volume "$1" | awk '{ printf "%d %d\n", $2 * 100 + 0.5, /MUTED/ }'
}

case "$1 ${2:-}" in
"vol up") wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ ;;
"vol down") wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
"vol mute") wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
"mic ") wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
"bri up") brightnessctl -q set 5%+ ;;
"bri down") brightnessctl -q -n2 set 5%- ;;
*) echo "usage: osd.sh vol up|down|mute | mic | bri up|down" >&2; exit 1 ;;
esac

case $1 in
vol)
	read -r pct muted < <(vol_of @DEFAULT_AUDIO_SINK@)
	if ((muted)); then icon=audio-volume-muted
	elif ((pct < 34)); then icon=audio-volume-low
	elif ((pct < 67)); then icon=audio-volume-medium
	else icon=audio-volume-high; fi
	osd volume "$pct" "$icon" "Volume$( ((muted)) && echo ' (muted)')"
	;;
mic)
	read -r pct muted < <(vol_of @DEFAULT_AUDIO_SOURCE@)
	if ((muted)); then osd mic "$pct" microphone-sensitivity-muted "Microphone (muted)"
	else osd mic "$pct" microphone-sensitivity-high "Microphone"; fi
	;;
bri)
	pct=$(brightnessctl -m | cut -d, -f4 | tr -d %)
	osd brightness "$pct" display-brightness "Brightness"
	;;
esac
