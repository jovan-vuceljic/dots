#!/bin/sh
# wallpaper.sh <image> — set the wallpaper now and keep it for the next login.
# wallpaper.sh         — (login) make sure a wallpaper is set, falling back to the default.
# hyprpaper.conf reads ~/.local/state/hypr/wallpaper, a link to the chosen image (outside the repo).
link=${XDG_STATE_HOME:-$HOME/.local/state}/hypr/wallpaper
default=$HOME/.config/hypr/wallpapers/foss_wallpaper_edit.png
mkdir -p "${link%/*}"

if [ -z "$1" ]; then
	[ -e "$link" ] || ln -sfn "$default" "$link"
	exit 0
fi

img=$(realpath -s "$1") || exit 1 # absolute, but keep links (stowed images stay under ~/.config)
ln -sfn "$img" "$link"
hyprctl hyprpaper wallpaper ",$img"
