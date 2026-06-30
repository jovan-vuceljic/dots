#!/usr/bin/env python3
"""Claude Code status line.

Row 1 (work):   dir | git(repo/branch +dirty +ahead/behind) | model |
                context% (+compact warn) | 5h usage (+reset eta) |
                cost (+burn rate) | line velocity | cache hit % | api/think ratio
Row 2 (system): RAM | disk | CPU% (+load +cores) | temp | version | output style

Reads the status JSON from stdin (Claude Code statusLine command). Every segment
is wrapped defensively so the status line can never crash the UI -- on any error
a segment is simply omitted.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import time
import unicodedata

# --- ANSI helpers -----------------------------------------------------------
RESET = "\033[0m"
DIM = ""  # disabled: "\033[2m" blended the gray detail text into dark backgrounds
BOLD = "\033[1m"
C = {
    "cyan": "\033[36m",
    "green": "\033[32m",
    "yellow": "\033[33m",
    "red": "\033[31m",
    "magenta": "\033[35m",
    "blue": "\033[34m",
    "gray": "\033[37m",  # light gray (was "\033[90m" bright-black, too dark to read)
}


def color(text, name="", dim=False, bold=False):
    pre = ""
    if dim:
        pre += DIM
    if bold:
        pre += BOLD
    pre += C.get(name, "")
    return f"{pre}{text}{RESET}" if pre else str(text)


def bucket(value, lo, hi, invert=False):
    """green/yellow/red by threshold. invert=True -> high is good."""
    if invert:
        return "green" if value >= hi else ("yellow" if value >= lo else "red")
    return "green" if value < lo else ("yellow" if value < hi else "red")


DIV = color(" │ ", "gray", dim=True)


def join_line(segs):
    return DIV.join(s for s in segs if s)


_ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


def vlen(text):
    """Visible width of a rendered string: ANSI stripped, emoji counted as 2."""
    text = _ANSI_RE.sub("", text)
    w = 0
    for ch in text:
        if ch in ("\u200d", "\ufe0f", "\ufe0e") or unicodedata.combining(ch):
            continue  # ZWJ / variation selectors / combining marks: zero width
        o = ord(ch)
        if o >= 0x1F000 or 0x2600 <= o <= 0x27BF or unicodedata.east_asian_width(ch) in ("W", "F"):
            w += 2
        else:
            w += 1
    return w


def term_cols():
    """Terminal width. Claude Code exports COLUMNS; 0 if unknown -> stay one line."""
    try:
        return shutil.get_terminal_size(fallback=(0, 0)).columns
    except Exception:
        return 0


# --- shared transcript usage ------------------------------------------------
def last_usage(data):
    """Most recent `message.usage` block from the transcript, or {}."""
    try:
        path = data.get("transcript_path")
        if not path or not os.path.exists(path):
            return {}
        usage = {}
        with open(path, "r", errors="ignore") as fh:
            for line in fh:
                line = line.strip()
                if not line or '"usage"' not in line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                msg = obj.get("message")
                if isinstance(msg, dict) and isinstance(msg.get("usage"), dict):
                    usage = msg["usage"]
        return usage
    except Exception:
        return {}


# --- row 1: work ------------------------------------------------------------
def dir_segment(cwd):
    try:
        home = os.path.expanduser("~")
        shown = cwd
        if cwd == home:
            shown = "~"
        elif cwd.startswith(home + os.sep):
            shown = "~" + cwd[len(home):]
        return "📁 " + color(shown, "cyan")
    except Exception:
        return ""


def _git(cwd, *args):
    return subprocess.run(
        ["git", "-C", cwd, *args], capture_output=True, text=True, timeout=1
    )


def git_segment(cwd):
    try:
        top = _git(cwd, "rev-parse", "--show-toplevel")
        if top.returncode != 0:
            return ""
        repo = os.path.basename(top.stdout.strip()) or "repo"
        branch = _git(cwd, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip() or "?"
        dirty = bool(_git(cwd, "status", "--porcelain").stdout.strip())

        # ahead/behind vs upstream (omitted when no upstream is configured)
        ab = ""
        rl = _git(cwd, "rev-list", "--left-right", "--count", "@{upstream}...HEAD")
        if rl.returncode == 0 and rl.stdout.strip():
            try:
                behind, ahead = (int(x) for x in rl.stdout.split())
                bits = []
                if ahead:
                    bits.append(color(f"↑{ahead}", "cyan"))
                if behind:
                    bits.append(color(f"↓{behind}", "yellow"))
                if bits:
                    ab = " " + "".join(bits)
            except Exception:
                ab = ""

        mark = color("*", "red") if dirty else ""
        label = color(repo, "magenta", bold=True)
        br = color(branch, "yellow" if dirty else "green")
        return f"🌿 {label} {br}{mark}{ab}"
    except Exception:
        return ""


def model_segment(data):
    name = (data.get("model") or {}).get("display_name")
    if not name:
        return ""
    name = name.replace(" context)", ")")  # "Opus 4.8 (1M context)" -> "Opus 4.8 (1M)"
    out = "🤖 " + color(name, "blue")
    level = (data.get("effort") or {}).get("level")
    if level:
        out += color(f" · {level}", "gray")
    return out


def context_segment(data, usage):
    try:
        if not usage:
            return ""
        used = (
            usage.get("input_tokens", 0)
            + usage.get("cache_creation_input_tokens", 0)
            + usage.get("cache_read_input_tokens", 0)
        )
        model_id = (data.get("model") or {}).get("id", "")
        window = 1_000_000 if "1m" in model_id.lower() else 200_000
        pct = used / window * 100 if window else 0
        col = bucket(pct, 50, 80)
        out = "📝 " + color(f"{pct:.0f}%", col) + color(f" ({used / 1000:.0f}k)", "gray", dim=True)
        if pct >= 80:
            out += color(" ⚠compact", "red", bold=True)
        return out
    except Exception:
        return ""


def usage_segment(data):
    """5-hour rolling usage window: used % (+ time until it resets)."""
    try:
        five = (data.get("rate_limits") or {}).get("five_hour") or {}
        pct = five.get("used_percentage")
        if pct is None:
            return ""
        out = "📊 " + color(f"{pct:.0f}%", bucket(pct, 50, 80))
        resets = five.get("resets_at")
        if resets:
            secs = int(resets) - int(time.time())
            if secs > 0:
                h, m = divmod(secs // 60, 60)
                out += color(f" {h}h{m:02d}m" if h else f" {m}m", "gray")
        return out
    except Exception:
        return ""


def cost_segment(data):
    try:
        cost = data.get("cost") or {}
        usd = cost.get("total_cost_usd")
        if usd is None:
            return ""
        out = "💰 " + color(f"${usd:.2f}", "yellow")
        dur_ms = cost.get("total_duration_ms") or 0
        if dur_ms > 30_000:  # need a meaningful window before extrapolating
            per_hr = usd / (dur_ms / 3_600_000)
            out += color(f" ${per_hr:.2f}/h", "gray", dim=True)
        return out
    except Exception:
        return ""


def velocity_segment(data):
    try:
        cost = data.get("cost") or {}
        added = cost.get("total_lines_added", 0)
        removed = cost.get("total_lines_removed", 0)
        if not (added or removed):
            return ""
        out = "✏️ " + color(f"+{added}", "green") + color("/", "gray", dim=True) + color(f"-{removed}", "red")
        dur_ms = cost.get("total_duration_ms") or 0
        if dur_ms > 30_000:
            per_min = added / (dur_ms / 60_000)
            out += color(f" {per_min:.0f}/m", "gray", dim=True)
        return out
    except Exception:
        return ""


def cache_segment(usage):
    try:
        if not usage:
            return ""
        read = usage.get("cache_read_input_tokens", 0)
        total = (
            usage.get("input_tokens", 0)
            + usage.get("cache_creation_input_tokens", 0)
            + read
        )
        if total <= 0:
            return ""
        pct = read / total * 100
        return "♻️ " + color(f"{pct:.0f}%", bucket(pct, 50, 80, invert=True))
    except Exception:
        return ""


def api_segment(data):
    """Share of wall-clock time spent in API/inference (rough 'busy' ratio)."""
    try:
        cost = data.get("cost") or {}
        wall = cost.get("total_duration_ms") or 0
        api = cost.get("total_api_duration_ms") or 0
        if wall <= 0 or api <= 0:
            return ""
        pct = min(api / wall * 100, 100)
        return "⚙️ " + color(f"{pct:.0f}%", "blue")
    except Exception:
        return ""


# --- row 2: system ----------------------------------------------------------
def ram_segment():
    try:
        info = {}
        with open("/proc/meminfo") as fh:
            for line in fh:
                k, _, v = line.partition(":")
                info[k.strip()] = int(v.split()[0])  # kB
        total = info.get("MemTotal", 0)
        avail = info.get("MemAvailable", info.get("MemFree", 0))
        if total <= 0:
            return ""
        used = total - avail
        pct = used / total * 100
        g = 1024 * 1024
        return (
            "🧠 " + color(f"{pct:.0f}%", bucket(pct, 70, 85))
            + color(f" {used / g:.1f}/{total / g:.0f}G", "gray", dim=True)
        )
    except Exception:
        return ""


def disk_segment(cwd):
    try:
        st = os.statvfs(cwd)
        total = st.f_blocks
        if total <= 0:
            return ""
        used = total - st.f_bfree
        pct = used / total * 100
        return "💾 " + color(f"{pct:.0f}%", bucket(pct, 75, 90))
    except Exception:
        return ""


def _cpu_pct():
    """Live CPU% diffed against a cached /proc/stat snapshot (no sleeping)."""
    try:
        with open("/proc/stat") as fh:
            parts = fh.readline().split()
        if not parts or parts[0] != "cpu":
            return None
        vals = [int(x) for x in parts[1:]]
        idle = vals[3] + (vals[4] if len(vals) > 4 else 0)  # idle + iowait
        total = sum(vals)

        state = os.path.expanduser("~/.claude/cache/statusline.cpu")
        prev = None
        try:
            with open(state) as fh:
                pt, pi = fh.read().split()
                prev = (int(pt), int(pi))
        except Exception:
            prev = None
        try:
            os.makedirs(os.path.dirname(state), exist_ok=True)
            with open(state, "w") as fh:
                fh.write(f"{total} {idle}")
        except Exception:
            pass

        if not prev:
            return None
        dt = total - prev[0]
        di = idle - prev[1]
        if dt <= 0 or di < 0:
            return None
        return max(0.0, min(100.0, (1 - di / dt) * 100))
    except Exception:
        return None


def cpu_segment():
    try:
        load1 = os.getloadavg()[0]
        cores = os.cpu_count() or 1
        pct = _cpu_pct()
        if pct is not None:
            head = color(f"{pct:.0f}%", bucket(pct, 60, 85))
            tail = color(f" {load1:.1f} {cores}c", "gray", dim=True)
        else:
            head = color(f"{load1:.2f}", bucket(load1 / cores, 0.7, 1.0))
            tail = color(f" {cores}c", "gray", dim=True)
        return "🖥️ " + head + tail
    except Exception:
        return ""


def temp_segment():
    """Hottest CPU-ish thermal zone in °C, falling back to the max zone."""
    try:
        base = "/sys/class/thermal"
        if not os.path.isdir(base):
            return ""
        prefer = ("x86_pkg_temp", "coretemp", "cpu", "k10temp", "tctl")
        chosen = None
        fallback = None
        for name in os.listdir(base):
            if not name.startswith("thermal_zone"):
                continue
            d = os.path.join(base, name)
            try:
                with open(os.path.join(d, "temp")) as fh:
                    milli = int(fh.read().strip())
            except Exception:
                continue
            ztype = ""
            try:
                with open(os.path.join(d, "type")) as fh:
                    ztype = fh.read().strip().lower()
            except Exception:
                pass
            if fallback is None or milli > fallback:
                fallback = milli
            if any(p in ztype for p in prefer) and (chosen is None or milli > chosen):
                chosen = milli
        milli = chosen if chosen is not None else fallback
        if milli is None:
            return ""
        c = milli / 1000.0
        return "🌡️ " + color(f"{c:.0f}°C", bucket(c, 60, 80))
    except Exception:
        return ""


def version_segment(data):
    v = data.get("version")
    return color(f"v{v}", "gray", dim=True) if v else ""


def style_segment(data):
    name = (data.get("output_style") or {}).get("name")
    return color(f"🎨{name}", "gray", dim=True) if name else ""


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}

    cwd = (
        (data.get("workspace") or {}).get("current_dir")
        or data.get("cwd")
        or os.getcwd()
    )
    usage = last_usage(data)

    # Two groups: work (left) and system (right). Rendered on one line when the
    # terminal is wide enough, otherwise stacked work-over-system.
    # Dormant helpers kept above for easy re-add: velocity_segment,
    # cache_segment, api_segment, version_segment, style_segment.
    work = [s for s in (
        dir_segment(cwd),
        git_segment(cwd),
        model_segment(data),
        context_segment(data, usage),
        usage_segment(data),
        cost_segment(data),
    ) if s]
    system = [s for s in (
        ram_segment(),
        cpu_segment(),
        temp_segment(),
        disk_segment(cwd),
    ) if s]

    one_line = join_line(work + system)
    cols = term_cols()
    if cols and vlen(one_line) > cols:
        sys.stdout.write(join_line(work) + "\n" + join_line(system))
    else:
        sys.stdout.write(one_line)


if __name__ == "__main__":
    main()
