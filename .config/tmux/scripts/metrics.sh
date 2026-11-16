#!/usr/bin/env bash
# metrics.sh full|compact — the status-right system segment in ONE process per refresh.
# (tmux used to spawn net dl, net ul, cpu, mem and temp as five separate #() jobs per tick.)
# Prints #[fg=…] style markers, which tmux honours inside #() output.
#   full    : net dl · net ul · cpu · mem · temp   (temp vanishes when no sensor exists)
#   compact : cpu · mem
# CPU and net are averaged over the interval since the PREVIOUS refresh: the /proc totals
# persist in $XDG_RUNTIME_DIR state files, so no sleeps and the value covers the whole
# status-interval. First run (no state yet) shows the since-boot average. Glyphs are Waybar's:
# cpu U+F035B, memory U+F0F86, thermometer U+F050F, download U+F019, upload U+F093.
mode=${1:-full}
rt="${XDG_RUNTIME_DIR:-/tmp}"

cpu() { # utilisation % since the previous refresh
  local st="$rt/tmux_cpu_stat" u n s i w rest idle tot v p_tot=0 p_idle=0 dt di
  read -r _ u n s i w rest </proc/stat
  idle=$((i + w))
  tot=$((u + n + s + i + w))
  for v in $rest; do tot=$((tot + v)); done
  [ -r "$st" ] && read -r p_tot p_idle <"$st"
  [ "$p_tot" -gt "$tot" ] && { p_tot=0; p_idle=0; } # stale state from a previous boot
  printf '%s %s\n' "$tot" "$idle" >"$st"
  dt=$((tot - p_tot))
  di=$((idle - p_idle))
  printf '\U000f035b '
  if [ "$dt" -le 0 ]; then printf -- '--%%'; else printf '%d%%' $(((100 * (dt - di) + dt / 2) / dt)); fi
}

mem() { # used = MemTotal - MemAvailable
  printf '\U000f0f86 '
  awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{if(t>0)printf "%d%%",(t-a)*100/t; else printf "--%%"}' /proc/meminfo
}

temp() { # CPU °C: a CPU-ish thermal zone, else a CPU hwmon chip, else the hottest zone; nothing if none
  local cpu_zone="" any_zone="" hw="" d t ty f
  for d in /sys/class/thermal/thermal_zone*/; do
    [ -r "${d}temp" ] && [ -r "${d}type" ] || continue
    t=$(<"${d}temp")
    case $t in '' | *[!0-9]*) continue ;; esac
    ty=$(<"${d}type"); ty=${ty,,}
    case $ty in *x86_pkg_temp* | *coretemp* | *k10temp* | *tctl* | *cpu*)
      if [ -z "$cpu_zone" ] || [ "$t" -gt "$cpu_zone" ]; then cpu_zone=$t; fi ;;
    esac
    if [ -z "$any_zone" ] || [ "$t" -gt "$any_zone" ]; then any_zone=$t; fi
  done
  if [ -z "$cpu_zone" ]; then
    for d in /sys/class/hwmon/hwmon*/; do
      [ -r "${d}name" ] || continue
      case $(<"${d}name") in coretemp | k10temp | zenpower | cpu_thermal)
        for f in "${d}"temp*_input; do
          [ -r "$f" ] || continue
          t=$(<"$f")
          case $t in '' | *[!0-9]*) continue ;; esac
          if [ -z "$hw" ] || [ "$t" -gt "$hw" ]; then hw=$t; fi
        done ;;
      esac
    done
  fi
  t=${cpu_zone:-${hw:-$any_zone}}
  [ -n "$t" ] || return 0
  printf '\U000f050f %d°  ' $(((t + 500) / 1000))
}

human() { awk -v b="$1" 'BEGIN{ split("B K M G T", u, " "); i=1;
  while (b >= 1024 && i < 5) { b /= 1024; i++ }
  if (i == 1) printf "%d%s", b, u[i]; else printf "%.1f%s", b, u[i] }'; }

net() { # sets dl/ul: bytes per second over all non-lo interfaces since the previous refresh
  local ctr="$rt/tmux_net_ctr" now rx tx prx ptx pnow drx=0 dtx=0 dt=1
  now=$(date +%s.%N)
  read -r rx tx < <(awk 'NR>2{gsub(/:/," "); if($1!="lo"){r+=$2; t+=$10}} END{print r+0, t+0}' /proc/net/dev)
  if [ -r "$ctr" ]; then
    read -r prx ptx pnow <"$ctr"
    dt=$(awk -v a="$now" -v b="$pnow" 'BEGIN{d=a-b; print (d>0.05)?d:1}')
    drx=$((rx - prx)); dtx=$((tx - ptx))
    [ "$drx" -lt 0 ] && drx=0
    [ "$dtx" -lt 0 ] && dtx=0
  fi
  printf '%s %s %s\n' "$rx" "$tx" "$now" >"$ctr"
  dl=$(human "$(awk -v x="$drx" -v d="$dt" 'BEGIN{printf "%d", x/d}')")
  ul=$(human "$(awk -v x="$dtx" -v d="$dt" 'BEGIN{printf "%d", x/d}')")
}

case $mode in
  compact)
    printf '#[fg=#89b4fa]%s  #[fg=#94e2d5]%s' "$(cpu)" "$(mem)"
    ;;
  *)
    net
    printf '#[fg=#a6e3a1]\U0000f019 %s #[fg=#f9e2af]\U0000f093 %s  #[fg=#89b4fa]%s  #[fg=#94e2d5]%s  #[fg=#fab387]%s' \
      "$dl" "$ul" "$(cpu)" "$(mem)" "$(temp)"
    ;;
esac
