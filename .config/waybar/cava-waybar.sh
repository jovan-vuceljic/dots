#!/usr/bin/env bash
# Self-contained waybar cava module: stream `cava` raw output as Unicode bar chars.
# No HyDE dependency — just needs `cava` installed. Usage: cava-waybar.sh [bars]
#   bars = number of columns (even; ~screen_px / (font-size * 0.6)); default 94.
#
# waybar's custom/cava module uses restart-interval, so this script is relaunched
# every time it exits. Without cleanup each relaunch would leak an orphaned `cava`
# child and they'd pile up. We enforce a single instance: track cava's own PID,
# kill it on exit, and reap any stale instance left by a previous (crashed) run.
bars="${1:-94}"
chars="▁▂▃▄▅▆▇█"   # cava ascii value 0..7 -> these

conf="$(mktemp)"
pidfile="${XDG_RUNTIME_DIR:-/tmp}/cava-waybar.pid"

cava_pid=""
cleanup() {
  [[ -n "$cava_pid" ]] && kill "$cava_pid" 2>/dev/null
  rm -f "$conf" "$pidfile"
}
trap cleanup EXIT INT TERM

# Reap a stale cava from a previous run that didn't clean up (e.g. hard kill).
if [[ -f "$pidfile" ]]; then
  old="$(cat "$pidfile" 2>/dev/null)"
  [[ "$old" =~ ^[0-9]+$ ]] && kill "$old" 2>/dev/null
fi

cat >"$conf" <<EOF
[general]
bars = $bars
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# sed program: drop the ';' separators, then map each digit 0..7 to its bar char
prog="s/;//g"
for i in 0 1 2 3 4 5 6 7; do
  prog+=";s/$i/${chars:$i:1}/g"
done

# Run cava in the background (not a `cava | sed` pipeline) so we hold its real PID
# and can kill it in cleanup. stdbuf -oL line-buffers cava so waybar gets each frame
# immediately (no choppy lag); its stdout is piped to sed via process substitution.
stdbuf -oL cava -p "$conf" > >(sed -u "$prog") &
cava_pid=$!
echo "$cava_pid" >"$pidfile"
wait "$cava_pid"
