#!/usr/bin/env bash
# CPU utilisation (%) averaged over the interval since the PREVIOUS status refresh:
# /proc/stat totals persist in a state file between runs (same pattern as net.sh),
# so the value covers the whole status-interval. (The old version slept 0.3s and
# sampled just that window — a 6% duty cycle that aliased bursty loads.) No sleep,
# ~5ms. First run (no state yet) shows the since-boot average. Glyph = Waybar's
# cpu module icon (U+F035B).
printf '\U000f035b '
rt="${XDG_RUNTIME_DIR:-/tmp}"
st="$rt/tmux_cpu_stat"   # previous totals:  tot idle

read -r _ u n s i w rest < /proc/stat
idle=$((i + w)); tot=$((u + n + s + i + w)); for v in $rest; do tot=$((tot + v)); done

p_tot=0; p_idle=0
[ -r "$st" ] && read -r p_tot p_idle < "$st"
[ "$p_tot" -gt "$tot" ] && { p_tot=0; p_idle=0; }   # stale state from a previous boot
printf '%s %s\n' "$tot" "$idle" > "$st"

dt=$((tot - p_tot)); di=$((idle - p_idle))
if [ "$dt" -le 0 ]; then printf -- '--%%'; else printf '%d%%' $(((100 * (dt - di) + dt / 2) / dt)); fi
