#!/bin/sh
# agent-next.sh: switch to the next window (after the current one, wrapping) that holds an
# agent mark you have not looked at yet; with none left, fall back to any grey mark; with
# nothing marked, say so. Bound to prefix+Tab and to the » tap target in the status bar.
cur=$(tmux display -p '#{window_index}')
pick() { # $1 empty = unseen marks only, "any" = grey ones too
  tmux list-panes -a -F '#{window_index} #{@agent} #{@agent_seen}' |
    awk -v c="$cur" -v any="$1" '
      $2 != "" && $2 != "busy" && (any != "" || $3 == "") { if ($1 > c && !n) n = $1; if (!f) f = $1 }
      END { if (n) print n; else if (f) print f }'
}
w=$(pick); [ -n "$w" ] || w=$(pick any)
if [ -n "$w" ]; then tmux select-window -t ":$w"; else tmux display-message "no agent waiting"; fi
