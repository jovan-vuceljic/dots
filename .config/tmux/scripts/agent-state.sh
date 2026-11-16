#!/bin/sh
# agent-state.sh <cc|oc|pi|cx> <busy|done|input|error|off>
#
# Per-pane "what is the agent in this pane doing" for tmux, shared by every agent's hooks:
# Claude Code (claude/settings.json), codex (~/.codex/hooks.json), pi (agent-state.ts
# extension) and opencode (plugins/agent-state.ts). No-op outside tmux.
#
# Which pane: $TMUX_PANE when the agent runs in the pane itself (pi, opencode, codex). Claude
# Code sessions run in a worker the claude daemon pre-spawned ("claude bg-spare"), whose
# environment has no tmux variables, so for them the worker is found by walking up the parent
# chain to the pid registered in ~/.claude/sessions/<pid>.json, and the pane is the one whose
# title Claude set to that session's name ("✳ <name>").
#
# Pane options read by tmux.conf's @agent_badge: @agent (the state, drawn as ✓ ? ! after the
# window name; busy draws nothing), @agent_seen (set by tmux's pane-focus-in hook: the glyph
# loses its colour once you visit the pane and stays, grey, until the next prompt turns the
# state busy) and @agent_tool (only the termux notification title uses it). `off` unsets all.
#
# Phone-level notice only for a NEW mark on a pane that is not in view: termux-notification
# when the agent runs natively in termux, otherwise a BEL into the pane (tmux forwards the bell
# to the outer terminal; termux's default bell-character=vibrate buzzes, and the window gets
# tmux's bell flag). A state change on an already-marked pane (e.g. Claude's idle_prompt ~60s
# after Stop turning done into input) only swaps the glyph: no second buzz, seen stays as is.
command -v tmux >/dev/null 2>&1 || exit 0
tool=$1 state=$2 pane=$TMUX_PANE
if [ -z "$pane" ]; then
  p=$$ worker=""
  for _ in 1 2 3 4 5 6 7 8; do
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
    [ -n "$p" ] && [ "$p" != 1 ] || break
    [ -f "$HOME/.claude/sessions/$p.json" ] && { worker=$p; break; }
  done
  [ -n "$worker" ] || exit 0
  name=$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1])).get("name",""))' \
    "$HOME/.claude/sessions/$worker.json" 2>/dev/null)
  [ -n "$name" ] || exit 0
  pane=$(tmux list-panes -a -F '#{pane_id}	#{pane_title}' 2>/dev/null |
    awk -F'\t' -v n="$name" '$2==n || substr($2,length($2)-length(n))==" " n {print $1; exit}')
  [ -n "$pane" ] || exit 0
fi
if [ "$state" = off ]; then
  for o in @agent @agent_seen @agent_tool; do tmux set -p -t "$pane" -u "$o" 2>/dev/null; done
  exit 0
fi
tmux set -p -t "$pane" @agent_tool "$tool" 2>/dev/null || exit 0 # no server reachable (sandbox): give up quietly
case $state in
  busy)
    tmux set -p -t "$pane" @agent busy
    tmux set -p -t "$pane" -u @agent_seen 2>/dev/null
    command -v termux-notification-remove >/dev/null 2>&1 && termux-notification-remove "agent-$pane"
    ;;
  *)
    already=$(tmux show -pv -t "$pane" @agent 2>/dev/null)
    tmux set -p -t "$pane" @agent "$state"
    if [ "$(tmux display -p -t "$pane" '#{pane_active}#{window_active}')" = 11 ]; then
      tmux set -p -t "$pane" @agent_seen 1 # in view: you saw it happen, so it starts out seen
      exit 0
    fi
    [ -n "$already" ] && [ "$already" != busy ] && exit 0 # glyph swapped on an existing mark
    tmux set -p -t "$pane" -u @agent_seen 2>/dev/null
    if command -v termux-notification >/dev/null 2>&1; then
      termux-notification --id "agent-$pane" --title "$tool: $state" --content "${PWD##*/}" \
        --vibrate 200 --action "tmux select-pane -t $pane"
    else
      printf '\a' > "$(tmux display -p -t "$pane" '#{pane_tty}')" 2>/dev/null
    fi
    ;;
esac
exit 0
