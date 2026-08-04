#!/usr/bin/env bash
# RAM utilisation (%) — used = MemTotal - MemAvailable, from /proc/meminfo.
# Called from tmux status-right via #(); cached per status-interval.
printf '\U000f0f86 '   # Waybar's memory glyph (U+F0F86), then the percentage
awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{if(t>0)printf "%d%%",(t-a)*100/t; else printf "--%%"}' /proc/meminfo
