#!/usr/bin/env bash
# Surface this repo's Claude Code config into ~/.claude via symlinks.
#
# `stow` deploys the repo to ~/.config/claude; Claude itself reads from ~/.claude,
# so we link the individual files/dirs across. Idempotent and self-healing: re-run
# any time. It also flags any file that has broken out of stow into a plain file —
# which silently stops Claude's edits from reaching the repo.
# (New skills/hooks added to the repo appear after a re-stow: `./install.sh` or `dotsync`.)
#
#   bash ~/.config/claude/link.sh
set -eu

SRC="$HOME/.config/claude"
DST="$HOME/.claude"

if [ ! -e "$SRC" ]; then
  echo "error: $SRC not found — run 'cd ~/.dots && ./install.sh' first" >&2
  exit 1
fi

mkdir -p "$DST"

# This repo's claude dir, resolved via link.sh's own symlink (location-independent).
repo=$(dirname "$(readlink -f "$SRC/link.sh")")

# If link.sh itself has broken out of stow into a plain file, $repo resolves to $SRC and
# the drift heal below would relink each drifted file onto ITSELF — destroying the only
# copy of its content. Refuse to continue.
if [ "$repo" = "$SRC" ]; then
  echo "error: link.sh itself is a plain file (broken out of stow) — re-stow first:" >&2
  echo "       cd ~/.dots && ./install.sh" >&2
  exit 1
fi

# Tracked items to expose in ~/.claude. Add new ones (e.g. commands agents) here.
items="settings.json statusline.py keybindings.json CLAUDE.md hooks skills"

# Expose each item in ~/.claude (where Claude actually reads).
for item in $items; do
  [ -e "$SRC/$item" ] || continue
  if [ -d "$DST/$item" ] && [ ! -L "$DST/$item" ]; then
    echo "skip   ~/.claude/$item (real directory in the way — move it aside first)" >&2
    continue
  fi
  # A plain FILE here means an atomic write replaced the link (Claude writes e.g.
  # ~/.claude/settings.json) — it may hold newer edits, so never clobber it silently:
  # heal only when provably lossless, warn otherwise (mirrors the SRC drift guard below).
  if [ -f "$DST/$item" ] && [ ! -L "$DST/$item" ]; then
    same=0
    case "$item" in
    *.json)
      python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1]))==json.load(open(sys.argv[2])) else 1)' \
        "$DST/$item" "$SRC/$item" 2>/dev/null && same=1 ;;
    *)
      cmp -s "$DST/$item" "$SRC/$item" && same=1 ;;
    esac
    if [ "$same" != 1 ]; then
      echo "DRIFT  ~/.claude/$item is a real file that differs from the repo copy —" >&2
      echo "       it may hold newer edits. Review, then re-link:" >&2
      echo "         diff '$DST/$item' '$SRC/$item'      # compare; keep whichever is right" >&2
      echo "         ln -sfn '$SRC/$item' '$DST/$item'   # re-link" >&2
      continue
    fi
    echo "healed ~/.claude/$item (plain copy identical to repo — re-linking)"
  fi
  ln -sfn "$SRC/$item" "$DST/$item"
  echo "linked ~/.claude/$item -> ~/.config/claude/$item"
done

# Stow-layer drift guard: each SRC *file* should be a symlink into the repo, so edits
# Claude writes (e.g. via /config) flow back and stay tracked. If an atomic write
# replaced one with a plain file, it has silently broken out of stow. Auto-heal only
# when provably lossless — the plain file is identical to the repo copy (JSON compared
# ignoring key order, since /config often just reorders keys). Otherwise warn and stop:
# the file may hold newer edits worth diffing in before re-linking.
for item in $items; do
  [ -f "$SRC/$item" ] && [ ! -L "$SRC/$item" ] || continue # a real file where a link belongs
  same=0
  if [ -f "$repo/$item" ]; then
    case "$item" in
    *.json)
      python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1]))==json.load(open(sys.argv[2])) else 1)' \
        "$SRC/$item" "$repo/$item" 2>/dev/null && same=1 ;;
    *)
      cmp -s "$SRC/$item" "$repo/$item" && same=1 ;;
    esac
  fi
  if [ "$same" = 1 ]; then
    ln -sfrn "$repo/$item" "$SRC/$item" # -r: relative link, so stow keeps owning it
    echo "healed ~/.config/claude/$item (plain copy identical to repo — re-linked)"
    continue
  fi
  echo "DRIFT  ~/.config/claude/$item is a real file that differs from the repo copy —" >&2
  echo "       it may hold edits not yet tracked. Review, then re-link:" >&2
  echo "         diff '$SRC/$item' '$repo/$item'      # compare; keep whichever is right" >&2
  echo "         ln -sfrn '$repo/$item' '$SRC/$item'  # re-link (relative, stow-owned)" >&2
done
