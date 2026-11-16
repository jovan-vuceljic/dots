#!/usr/bin/env bash
# screenshot.sh area|output|screen — grim → satty. In satty: Enter copies AND saves
# to ~/Pictures/Screenshots, Esc discards.
dir=${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots
mkdir -p "$dir"

case ${1:-area} in
area) geo=$(slurp -d) || exit 0; args=(-g "$geo") ;;
output) args=(-o "$(hyprctl activeworkspace -j | jq -r .monitor)") ;;
screen) args=() ;;
*) echo "usage: screenshot.sh area|output|screen" >&2; exit 1 ;;
esac

grim "${args[@]}" - | satty --filename - \
	--output-filename "$dir/%Y-%m-%d_%H-%M-%S.png" \
	--copy-command wl-copy \
	--actions-on-enter save-to-clipboard,save-to-file,exit \
	--early-exit all
