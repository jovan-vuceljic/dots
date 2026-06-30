# Status line (`statusline.py`)

The custom Claude Code status line. It renders as **one line**, segments joined by a
light-gray `│`, ordered **work info (left) → system info (right)**:

```
📁 ~/.dotfiles │ 🌿 .dotfiles main* │ 🤖 Opus 4.8 · xhigh │ 📝 84% (843k) │ 📊 34% 2h54m │ 💰 $0.40 $12.00/h │ 🧠 51% 15.9/31G │ 🖥️ 89% 9.5 12c │ 🌡️ 84°C │ 💾 81%
```

Every segment is defensive: if its data is missing or a command fails, the segment is
simply omitted (the bar never crashes the UI). Secondary detail (the parts in light gray)
is supplementary to the main colored value.

## Live segments

| | Segment | Shows | Notes |
|---|---|---|---|
| 📁 | **Directory** | Current working dir, with `~` for home | cyan |
| 🌿 | **Git** | `repo branch` + `*` if dirty + `↑N`/`↓N` ahead/behind upstream | repo = magenta; branch = green when clean, yellow + red `*` when dirty; `↑` cyan, `↓` yellow. Omitted outside a repo |
| 🤖 | **Model** | Active model display name + `· effort` level (`low`/`medium`/`high`/`xhigh`) | name = blue, effort = light gray; effort omitted for models without the param |
| 📝 | **Context** | `% of context window used` + `(Nk)` tokens | window = 1M for `[1m]` models, else 200k. Adds a red **⚠compact** at ≥80% |
| 📊 | **5h usage** | `% of the 5-hour rolling limit used` + time until it resets | from `rate_limits.five_hour`; Pro/Max only, and absent until the first API response of a session |
| 💰 | **Cost** | `$` session cost so far + `$/h` burn rate | burn rate shown once the session exceeds ~30s |
| 🧠 | **RAM** | `% used` + `used/totalG` | from `/proc/meminfo` |
| 🖥️ | **CPU** | `% busy` + `loadavg cores`c | live %, diffed against a cached `/proc/stat` snapshot; falls back to load average if % can't be computed |
| 🌡️ | **Temp** | Hottest CPU thermal zone in °C | prefers `x86_pkg_temp`/`coretemp`/`k10temp`; omitted if no sensors |
| 💾 | **Disk** | `% used` of the filesystem at the cwd | from `statvfs` |

## Colour legend

Most numbers are **green / yellow / red** by threshold — green = healthy, red = needs
attention. Light gray = secondary detail. Thresholds (`green < … < yellow < … ≤ red`):

| Segment | green | yellow | red |
|---|---|---|---|
| Context | `< 50%` | `50–80%` | `≥ 80%` (⚠compact) |
| 5h usage | `< 50%` | `50–80%` | `≥ 80%` |
| RAM | `< 70%` | `70–85%` | `≥ 85%` |
| CPU | `< 60%` | `60–85%` | `≥ 85%` |
| Temp | `< 60°C` | `60–80°C` | `≥ 80°C` |
| Disk | `< 75%` | `75–90%` | `≥ 90%` |

> Light gray is `\033[37m`; dimming (`\033[2m`) is disabled because it blended the gray
> detail text into dark terminal backgrounds. To go brighter, set `"gray"` to `\033[97m`
> (bright white) in the `C` table near the top of `statusline.py`.

## Optional segments (defined but not shown)

These functions exist in `statusline.py` but aren't in the output. Enable one by adding it
to the `work` or `system` list in `main()`:

| | Function | Shows |
|---|---|---|
| ✏️ | `velocity_segment` | `+added/-removed` lines this session + lines/min |
| ♻️ | `cache_segment` | prompt-cache hit % (higher is better) |
| ⚙️ | `api_segment` | share of wall-clock time spent in API/inference |
| | `version_segment` | Claude Code version (`vX.Y.Z`) |
| 🎨 | `style_segment` | active output-style name |

## Where it lives

`statusline.py` is tracked in this repo and symlinked to `~/.claude/statusline.py`;
`settings.json` runs it via `statusLine` (`/usr/bin/env python3 ~/.claude/statusline.py`).
Edits take effect on the next status refresh.
