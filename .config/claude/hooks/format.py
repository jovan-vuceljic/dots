#!/usr/bin/env python3
"""PostToolUse hook: format an edited file with the right formatter.

Reads the hook JSON from stdin, extracts the edited file path, and runs a
language-appropriate formatter -- but, to avoid imposing a style on a project
that never asked for it, opinionated formatters (stylua, ruff, prettier) only
run when the project opts in via a config file discoverable by walking up from
the edited file. Canonical single-style toolchains (gofmt, rustfmt) run when
their project marker (go.mod / Cargo.toml) is present.

Best-effort: always exits 0 so a format hiccup never blocks an edit. jq is not
guaranteed on the host, hence python for the stdin JSON parse.
"""
import json
import os
import shutil
import subprocess
import sys


def find_up(start, names):
    """Nearest ancestor dir (incl. the file's own) containing any of `names`."""
    d = os.path.dirname(os.path.abspath(start))
    while True:
        if any(os.path.exists(os.path.join(d, n)) for n in names):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def has_toml_section(start, filename, section):
    """True if the nearest ancestor `filename` contains `section`."""
    d = find_up(start, [filename])
    if not d:
        return False
    try:
        with open(os.path.join(d, filename), errors="ignore") as fh:
            return section in fh.read()
    except Exception:
        return False


def stylua_cmd(path):
    exe = os.path.expanduser("~/.local/share/nvim/mason/bin/stylua")
    if not os.access(exe, os.X_OK):
        exe = shutil.which("stylua")
    if exe and find_up(path, [".stylua.toml", "stylua.toml"]):
        return [exe, path]
    return None


def ruff_cmd(path):
    exe = shutil.which("ruff")
    if exe and (find_up(path, ["ruff.toml", ".ruff.toml"])
                or has_toml_section(path, "pyproject.toml", "[tool.ruff")):
        return [exe, "format", path]
    return None


_PRETTIER_CFGS = [
    ".prettierrc", ".prettierrc.json", ".prettierrc.yaml", ".prettierrc.yml",
    ".prettierrc.json5", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.mjs",
    ".prettierrc.toml", "prettier.config.js", "prettier.config.cjs",
    "prettier.config.mjs",
]


def prettier_cmd(path):
    exe = shutil.which("prettier")
    if exe and find_up(path, _PRETTIER_CFGS):
        return [exe, "--write", path]
    return None


def gofmt_cmd(path):
    exe = shutil.which("gofmt")
    if exe and find_up(path, ["go.mod"]):  # one canonical style
        return [exe, "-w", path]
    return None


def rustfmt_cmd(path):
    exe = shutil.which("rustfmt")
    if exe and find_up(path, ["Cargo.toml", "rustfmt.toml", ".rustfmt.toml"]):
        return [exe, path]
    return None


HANDLERS = {
    ".lua": stylua_cmd,
    ".py": ruff_cmd,
    ".js": prettier_cmd, ".jsx": prettier_cmd, ".mjs": prettier_cmd,
    ".cjs": prettier_cmd, ".ts": prettier_cmd, ".tsx": prettier_cmd,
    ".css": prettier_cmd, ".scss": prettier_cmd, ".less": prettier_cmd,
    ".html": prettier_cmd, ".vue": prettier_cmd, ".json": prettier_cmd,
    ".md": prettier_cmd, ".yaml": prettier_cmd, ".yml": prettier_cmd,
    ".go": gofmt_cmd,
    ".rs": rustfmt_cmd,
}


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    ti = data.get("tool_input") or {}
    tr = data.get("tool_response") or {}
    path = ti.get("file_path") or tr.get("filePath") or ""
    if not path or not os.path.isfile(path):
        return
    handler = HANDLERS.get(os.path.splitext(path)[1].lower())
    if not handler:
        return
    cmd = handler(path)
    if not cmd:
        return
    try:
        subprocess.run(cmd, timeout=15, capture_output=True)
    except Exception:
        pass


if __name__ == "__main__":
    main()
