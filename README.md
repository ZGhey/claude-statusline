# claude-statusline

A tiny, dependency-light status line for [Claude Code](https://code.claude.com).
One POSIX `sh` script, no Node, no daemon — just `jq` and `awk`.

```
~/.hermes  opus4.8  ctx:42%  1m35s  $0.42  main  +156/-23  │  used:35%  resets:10:00
```

## What it shows

**Left group (active info):**

| Segment | Example | Meaning |
|---------|---------|---------|
| Directory | `~/.hermes` | Current working dir (cyan, `~`-shortened) |
| Model | `opus4.8` | Active model, short form |
| Context | `ctx:42%` | Context window used — green / yellow (≥50%) / red (>80%) |
| Duration | `1m35s` | Session wall-clock time |
| Cost | `$0.42` | Session cost in USD (hidden below 1¢) |
| Branch | `main` | Git branch |
| Lines | `+156/-23` | Lines added / removed by Claude this session |

**Right group (dimmed, rate limits):**

| Segment | Example | Meaning |
|---------|---------|---------|
| Used | `used:35%` | 5-hour rate-limit usage — green / yellow / red |
| Resets | `resets:10:00` | When the 5-hour window resets |

Segments hide themselves when their data isn't available, so the line stays clean.

## Install

```sh
git clone https://github.com/ZGhey/claude-statusline.git
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

## Customizing

Everything is in `statusline-command.sh`. Colors are ANSI escapes defined at the
top; each segment is a small, clearly-numbered block you can reorder or drop.

**Want git working-tree diff instead of Claude's session lines?** Replace the
`total_lines_added/removed` lookups in segment 7 with a `git -C "$current_dir"
diff --shortstat` call. (Default uses the JSON values for zero subprocess cost.)

## License

MIT
