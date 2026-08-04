#!/usr/bin/env bash
# Network throughput from /proc/net/dev (sum of all non-lo interfaces), averaged
# over the interval between status refreshes — no blocking sleep.
#
# Usage:  net.sh dl   ->  " 1.2M"   (download icon U+F019 + rate)
#         net.sh ul   ->  " 45K"   (upload   icon U+F093 + rate)
#
# tmux calls both from status-right. A short (<3s) cache lets the two calls of a
# single refresh share one computation, so the up/down figures are consistent and
# only one of them re-samples the counters per refresh.
which=${1:-dl}
rt="${XDG_RUNTIME_DIR:-/tmp}"
ctr="$rt/tmux_net_ctr"      # previous counters:  rx tx epoch.ns
cache="$rt/tmux_net_cache"  # computed rates:     dl_rate ul_rate epoch_s

emit() { # emit <icon-printf-escape> <rate>
  printf "$1 %s" "$2"
}

# Reuse a fresh cache so dl and ul agree and we only sample once per refresh.
if [ -r "$cache" ]; then
  read -r cdl cul cts < "$cache"
  if [ -n "$cts" ] && [ "$(( $(date +%s) - cts ))" -lt 3 ]; then
    if [ "$which" = ul ]; then emit '\U0000f093' "$cul"; else emit '\U0000f019' "$cdl"; fi
    exit 0
  fi
fi

now=$(date +%s.%N)
read -r rx tx < <(awk 'NR>2{gsub(/:/," "); if($1!="lo"){r+=$2; t+=$10}} END{print r+0, t+0}' /proc/net/dev)

drx=0; dtx=0; dt=1
if [ -r "$ctr" ]; then
  read -r prx ptx pnow < "$ctr"
  dt=$(awk -v a="$now" -v b="$pnow" 'BEGIN{d=a-b; print (d>0.05)?d:1}')
  drx=$(( rx - prx )); dtx=$(( tx - ptx ))
  [ "$drx" -lt 0 ] && drx=0
  [ "$dtx" -lt 0 ] && dtx=0
fi
printf '%s %s %s\n' "$rx" "$tx" "$now" > "$ctr"

human() { awk -v b="$1" 'BEGIN{ split("B K M G T", u, " "); i=1;
  while (b >= 1024 && i < 5) { b /= 1024; i++ }
  if (i == 1) printf "%d%s", b, u[i]; else printf "%.1f%s", b, u[i] }'; }

dl=$(human "$(awk -v x="$drx" -v d="$dt" 'BEGIN{printf "%d", x/d}')")
ul=$(human "$(awk -v x="$dtx" -v d="$dt" 'BEGIN{printf "%d", x/d}')")
printf '%s %s %s\n' "$dl" "$ul" "$(date +%s)" > "$cache"

if [ "$which" = ul ]; then emit '\U0000f093' "$ul"; else emit '\U0000f019' "$dl"; fi
