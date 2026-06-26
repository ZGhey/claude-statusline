# claude-statusline

[![shellcheck](https://github.com/ZGhey/claude-statusline/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/ZGhey/claude-statusline/actions/workflows/shellcheck.yml)
[![release](https://img.shields.io/github/v/release/ZGhey/claude-statusline)](https://github.com/ZGhey/claude-statusline/releases/latest)

**English** · [简体中文](README.zh-CN.md)

A tiny, dependency-light status line for [Claude Code](https://code.claude.com).
One POSIX `sh` script, no Node, no daemon — just `jq` and `awk`.

![claude-statusline](docs/statusline.svg)

## What it shows

**Left group (active info):**

| Segment | Example | Meaning |
|---------|---------|---------|
| Directory | `~/.claude` | Current working dir (cyan, `~`-shortened) |
| Model | `opus4.8` | Active model, short form |
| Context | `ctx:42%` | Context window used — green / yellow (≥50%) / red (>80%) |
| Duration | `1m35s` | Session wall-clock time |
| Cost | `$1.84` | Session cost in USD — **shown only on API/console billing**, hidden for subscribers (see below) |
| Branch | `main` | Git branch |
| Lines | `+156/-23` | Lines added / removed by Claude this session |

**Right group (dimmed, rate limits):**

| Segment | Example | Meaning |
|---------|---------|---------|
| 5h | `5h:35%` | 5-hour rate-limit usage — green / yellow (≥50%) / red (>80%) |
| Resets | `resets:10:00` | When the 5-hour window resets (the near-term one) |
| 7d | `7d:58%` | 7-day (weekly) rate-limit usage, same color thresholds — sits last as the least time-sensitive |

Segments hide themselves when their data isn't available, so the line stays clean.

## Cost & subscriptions

`cost.total_cost_usd` is a **client-side estimate** that, per Claude Code's docs,
"may differ from your actual bill." For Claude.ai **Pro/Max subscribers** it's just
an API-equivalent figure — you pay a flat subscription, not per token — so showing
it is misleading.

The status JSON exposes no billing field, but `rate_limits` is present **only for
subscribers**. The script uses that as the signal:

- **Subscriber** (`rate_limits` present) → cost **hidden**
- **API / console billing** (no `rate_limits`) → cost **shown** (it's your real bill)

Force the cost segment on regardless with an env var:

```sh
export STATUSLINE_SHOW_COST=1
```

## Install

```sh
git clone https://github.com/ZGhey/claude-statusline.git
cd claude-statusline
./install.sh
```

Pin to a tagged release (`v0.1.0`) instead of tracking `main`:

```sh
git clone --branch v0.1.0 --depth 1 https://github.com/ZGhey/claude-statusline.git
cd claude-statusline
./install.sh
```

The installer copies `statusline-command.sh` to `~/.claude/` and registers it in
`~/.claude/settings.json` under `statusLine` (it **merges**, so your other
settings are preserved). Start a new session to see it.

> Honors `$CLAUDE_CONFIG_DIR` if you keep your Claude config elsewhere.

### Manual install

If you'd rather not run the script, copy `statusline-command.sh` anywhere and add
this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh /absolute/path/to/statusline-command.sh"
  }
}
```

## Requirements

- `jq` — parses the status JSON Claude Code sends on stdin
- `awk` — float math for the cost segment

Both ship with macOS and most Linux distros. On macOS without `jq`:
`brew install jq`.

### Platform support

Cross-platform — a single POSIX `sh` script with no OS-specific assumptions.
The one place platforms differ (`date`: BSD `-r` vs GNU `-d @`) is handled with
a fallback, so the reset time renders everywhere.

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | ✅ | Works out of the box (`jq`/`awk` preinstalled) |
| Linux | ✅ | Needs `jq` (`apt install jq` / `dnf install jq` / etc.) |
| Windows | ✅ via Git Bash or WSL | Claude Code runs the `sh` command there; install `jq` (`scoop install jq` / WSL package manager) |

## Customizing

Everything is in `statusline-command.sh`. Colors are ANSI escapes defined at the
top; each segment is a small, clearly-numbered block you can reorder or drop.

**Want git working-tree diff instead of Claude's session lines?** Replace the
`total_lines_added/removed` lookups in segment 7 with a `git -C "$current_dir"
diff --shortstat` call. (Default uses the JSON values for zero subprocess cost.)

## License

MIT
