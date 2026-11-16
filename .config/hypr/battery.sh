#!/usr/bin/env bash
# Battery readout for the hyprlock label. Prints nothing on machines without a
# battery (wm desktop), so the label just stays empty there.
for bat in /sys/class/power_supply/BAT*; do
  [ -r "$bat/capacity" ] || continue
  cap=$(<"$bat/capacity")
  glyph="󰁹"
  [ "$(cat "$bat/status" 2>/dev/null)" = "Charging" ] && glyph="󰂄"
  printf '%s %s%%' "$glyph" "$cap"
  exit 0
done
