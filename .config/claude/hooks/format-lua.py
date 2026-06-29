#!/usr/bin/env python3
"""PostToolUse hook: format an edited .lua file with stylua.

Reads the hook JSON from stdin, extracts the edited file path, and runs the
Mason-installed stylua on it -- but only when a .stylua.toml / stylua.toml is
discoverable by walking up from the file, so we never impose stylua's tab
defaults on files outside a configured project (e.g. ~/.dots/.config/nvim).

Best-effort: always exits 0 so a format hiccup never blocks an edit. jq is not
installed on this host, hence python for the stdin JSON parse.
"""
import json
import os
import subprocess
import sys

STYLUA = os.path.expanduser("~/.local/share/nvim/mason/bin/stylua")


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    ti = data.get("tool_input") or {}
    tr = data.get("tool_response") or {}
    path = ti.get("file_path") or tr.get("filePath") or ""
    if not path.endswith(".lua") or not os.path.isfile(path):
        return
    if not os.access(STYLUA, os.X_OK):
        return
    # Only format where the user has defined a stylua style.
    d = os.path.dirname(os.path.abspath(path))
    while True:
        if os.path.isfile(os.path.join(d, ".stylua.toml")) or os.path.isfile(os.path.join(d, "stylua.toml")):
            break
        parent = os.path.dirname(d)
        if parent == d:
            return  # no config found -> leave the file alone
        d = parent
    try:
        subprocess.run([STYLUA, path], timeout=15)
    except Exception:
        pass


if __name__ == "__main__":
    main()
