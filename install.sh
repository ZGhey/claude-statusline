#!/bin/sh
# Installer for claude-statusline.
# Copies statusline-command.sh into ~/.claude/ and registers it in
# ~/.claude/settings.json under the "statusLine" key (merging, not clobbering).
#
# Usage:  ./install.sh
# Requires: jq (for safe settings.json merge). Without jq the script is still
# copied, and you are shown the snippet to paste into settings.json manually.

set -e

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
SRC_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT_SRC="$SRC_DIR/statusline-command.sh"
SCRIPT_DST="$CLAUDE_DIR/statusline-command.sh"

printf 'Installing claude-statusline into %s\n' "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"

# 1. Copy the statusline script.
cp "$SCRIPT_SRC" "$SCRIPT_DST"
chmod +x "$SCRIPT_DST"
printf '  ok  copied script -> %s\n' "$SCRIPT_DST"

# The statusLine block we want in settings.json.
STATUSLINE_JSON=$(cat <<EOF
{
  "type": "command",
  "command": "sh $SCRIPT_DST"
}
EOF
)

# 2. Register it in settings.json.
if command -v jq >/dev/null 2>&1; then
  if [ -f "$SETTINGS" ]; then
    tmp=$(mktemp)
    jq --argjson sl "$STATUSLINE_JSON" '.statusLine = $sl' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    printf '  ok  merged statusLine into existing %s\n' "$SETTINGS"
  else
    jq -n --argjson sl "$STATUSLINE_JSON" '{statusLine: $sl}' > "$SETTINGS"
    printf '  ok  created %s with statusLine\n' "$SETTINGS"
  fi
else
  printf '  !!  jq not found — could not edit settings.json automatically.\n'
  printf '      Add this to %s manually:\n\n' "$SETTINGS"
  printf '  "statusLine": %s\n\n' "$STATUSLINE_JSON"
fi

printf 'Done. Start a new Claude Code session (or /statusline) to see it.\n'
