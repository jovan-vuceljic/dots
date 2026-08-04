#!/usr/bin/env bash
# CPU temperature (°C) for the tmux status bar (thermometer glyph U+F050F).
# Sensor hunt, most→least specific: a CPU-ish thermal zone (x86_pkg_temp/…),
# else a CPU hwmon chip (coretemp/k10temp/…), else the hottest remaining zone
# (acpitz can be a bogus constant on desktops, hence last). Prints NOTHING when
# no sensor exists (VMs/containers) so the segment simply disappears — which is
# also why the trailing spacing lives in here, not in status-right.
cpu_zone=""; any_zone=""; hw=""

for d in /sys/class/thermal/thermal_zone*/; do
  [ -r "${d}temp" ] && [ -r "${d}type" ] || continue
  t=$(<"${d}temp")
  case $t in ''|*[!0-9]*) continue ;; esac
  ty=$(<"${d}type"); ty=${ty,,}
  case $ty in *x86_pkg_temp*|*coretemp*|*k10temp*|*tctl*|*cpu*)
    if [ -z "$cpu_zone" ] || [ "$t" -gt "$cpu_zone" ]; then cpu_zone=$t; fi ;;
  esac
  if [ -z "$any_zone" ] || [ "$t" -gt "$any_zone" ]; then any_zone=$t; fi
done

if [ -z "$cpu_zone" ]; then
  for d in /sys/class/hwmon/hwmon*/; do
    [ -r "${d}name" ] || continue
    case $(<"${d}name") in coretemp|k10temp|zenpower|cpu_thermal)
      for f in "${d}"temp*_input; do
        [ -r "$f" ] || continue
        t=$(<"$f")
        case $t in ''|*[!0-9]*) continue ;; esac
        if [ -z "$hw" ] || [ "$t" -gt "$hw" ]; then hw=$t; fi
      done ;;
    esac
  done
fi

t=${cpu_zone:-${hw:-$any_zone}}
[ -n "$t" ] || exit 0
printf '\U000f050f %d°  ' $(( (t + 500) / 1000 ))
