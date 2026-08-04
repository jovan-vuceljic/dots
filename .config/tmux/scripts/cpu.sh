#!/usr/bin/env bash
# Instantaneous CPU utilisation (%) from two /proc/stat samples, prefixed with
# the same Nerd Font glyph Waybar's cpu module uses (U+F035B). Called from tmux
# status-right via #(); tmux caches it per status-interval, so the 0.3s sample
# never blocks the UI.
printf '\U000f035b '
read -r _ u n s i w rest < /proc/stat
p_idle=$((i + w)); p_tot=$((u + n + s + i + w)); for v in $rest; do p_tot=$((p_tot + v)); done
sleep 0.3
read -r _ u n s i w rest < /proc/stat
idle=$((i + w)); tot=$((u + n + s + i + w)); for v in $rest; do tot=$((tot + v)); done
dt=$((tot - p_tot)); di=$((idle - p_idle))
if [ "$dt" -le 0 ]; then printf '--%%'; else printf '%d%%' $(((100 * (dt - di) + dt / 2) / dt)); fi
