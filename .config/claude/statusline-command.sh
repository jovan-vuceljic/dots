#!/usr/bin/env bash
BLUE=$'\033[34m'
YELLOW=$'\033[33m'
RESET=$'\033[0m'

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // .model // ""')
ctx_pct=$(echo "$input" | jq -r 'if .context_window.used_percentage then (.context_window.used_percentage | tostring) + "%" else "" end')
branch=$(git -C "$cwd" branch --show-current 2>/dev/null)

home_dir="$HOME"
short_cwd="${cwd/#$home_dir/\~}"

parts="${BLUE}${short_cwd}${RESET}"
[ -n "$branch" ] && parts="${parts} ${YELLOW}${branch}${RESET}"
[ -n "$model" ]   && parts="${parts} | ${model}"
[ -n "$ctx_pct" ] && parts="${parts} | ctx ${ctx_pct}"

printf "[%s@%s %s]" "$(whoami)" "$(hostname -s)" "$parts"
