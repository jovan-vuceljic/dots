#!/usr/bin/env bash
# Surface this dotfiles' Claude Code config into ~/.claude via symlinks.
#
# `stow` deploys the repo to ~/.config/claude; Claude itself reads from ~/.claude,
# so we link the individual files/dirs across. Idempotent and self-healing: re-run
# any time (e.g. if Claude's /config ever replaces a link with a plain file).
#
#   bash ~/.config/claude/link.sh
set -eu

SRC="$HOME/.config/claude"
DST="$HOME/.claude"

if [ ! -e "$SRC" ]; then
  echo "error: $SRC not found — run 'cd ~ && stow .dotfiles' first" >&2
  exit 1
fi

mkdir -p "$DST"

# Tracked items to expose in ~/.claude. Add new ones (e.g. commands agents) here.
items="settings.json statusline.py keybindings.json CLAUDE.md hooks"

for item in $items; do
  [ -e "$SRC/$item" ] || continue
  if [ -d "$DST/$item" ] && [ ! -L "$DST/$item" ]; then
    echo "skip   ~/.claude/$item (real directory in the way — move it aside first)" >&2
    continue
  fi
  ln -sfn "$SRC/$item" "$DST/$item"
  echo "linked ~/.claude/$item -> ~/.config/claude/$item"
done
