#!/bin/sh
# Claude Code status line
# Reads JSON from stdin; requires jq.
# Left group (always-on): dir  model  ctx:XX%  duration  branch
# Right group (always-on, dimmed): │  used:XX%  resets:HH:MM
#   used:XX% gets green/yellow/red color when data is present; placeholders shown otherwise.

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf 'dir: ? model: ? ctx: ? resets: ?'
  exit 0
fi

# ANSI color helpers (reset after each segment to prevent bleed)
CYAN='\033[36m'
YELLOW='\033[33m'
WHITE='\033[37m'
GREEN='\033[32m'
RED='\033[31m'
MAGENTA='\033[35m'
DIM='\033[2m'
RESET='\033[0m'

# 1. Current directory (full path with ~ substitution)
current_dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // empty')
dir_part=""
if [ -n "$current_dir" ] && [ "$current_dir" != "null" ]; then
  case "$current_dir" in
    "$HOME"*) dir_display="~${current_dir#"$HOME"}" ;;
    *)        dir_display="$current_dir" ;;
  esac
  dir_part=$(printf "${CYAN}%s${RESET}" "$dir_display")
fi

# 2. Model id (short form: strip "claude-" prefix, keep family + major.minor, drop date suffix)
model_id=$(printf '%s' "$input" | jq -r '.model.id // empty')
model_part=""
if [ -n "$model_id" ] && [ "$model_id" != "null" ]; then
  short=$(printf '%s' "$model_id" | sed -E 's/^claude-([^-]+)-([0-9]+)-([0-9]+).*/\1\2.\3/')
  model_part=$(printf "${YELLOW}%s${RESET}" "$short")
fi

# 3. Context used percentage formatted as "ctx:XX%" with color thresholds
used=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
ctx_part=""
if [ -n "$used" ] && [ "$used" != "null" ]; then
  pct=$(printf '%.0f' "$used")
  if [ "$pct" -gt 80 ]; then
    color="$RED"
  elif [ "$pct" -ge 50 ]; then
    color="$YELLOW"
  else
    color="$GREEN"
  fi
  ctx_part=$(printf "${color}ctx:%s%%${RESET}" "$pct")
fi

# 4. Session duration from .cost.total_duration_ms (white, only when present)
duration_ms=$(printf '%s' "$input" | jq -r '.cost.total_duration_ms // empty')
duration_part=""
if [ -n "$duration_ms" ] && [ "$duration_ms" != "null" ]; then
  total_s=$(( duration_ms / 1000 ))
  if [ "$total_s" -lt 60 ]; then
    duration_str="${total_s}s"
  elif [ "$total_s" -lt 3600 ]; then
    m=$(( total_s / 60 ))
    s=$(( total_s % 60 ))
    duration_str="${m}m${s}s"
  else
    h=$(( total_s / 3600 ))
    m=$(( (total_s % 3600) / 60 ))
    duration_str="${h}h${m}m"
  fi
  duration_part=$(printf "${WHITE}%s${RESET}" "$duration_str")
fi

# 5. Session cost in USD from .cost.total_cost_usd (magenta, only when >= 1 cent)
cost_usd=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // empty')
cost_part=""
if [ -n "$cost_usd" ] && [ "$cost_usd" != "null" ]; then
  show_cost=$(awk -v c="$cost_usd" 'BEGIN { print (c + 0 >= 0.005) ? 1 : 0 }')
  if [ "$show_cost" = "1" ]; then
    cost_str=$(awk -v c="$cost_usd" 'BEGIN { printf "$%.2f", c }')
    cost_part=$(printf "${MAGENTA}%s${RESET}" "$cost_str")
  fi
fi

# 6. Git branch (green, only when present)
git_branch=$(printf '%s' "$input" | jq -r '.workspace.git_branch // empty')
branch_part=""
if [ -n "$git_branch" ] && [ "$git_branch" != "null" ]; then
  branch_part=$(printf "${GREEN}%s${RESET}" "$git_branch")
fi

# 7. Lines added/removed this session from .cost.total_lines_added/removed
#    Rendered as +A/-R (green/red), only when there is at least one change.
lines_added=$(printf '%s' "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(printf '%s' "$input" | jq -r '.cost.total_lines_removed // 0')
[ "$lines_added" = "null" ] && lines_added=0
[ "$lines_removed" = "null" ] && lines_removed=0
lines_part=""
if { [ "$lines_added" -gt 0 ] 2>/dev/null; } || { [ "$lines_removed" -gt 0 ] 2>/dev/null; }; then
  lines_part=$(printf "${GREEN}+%s${RESET}/${RED}-%s${RESET}" "$lines_added" "$lines_removed")
fi

# 8. Right group: separator + used:XX% + resets:HH:MM — always rendered, dimmed.
#    used:XX% gets color when data is present; placeholders (--) when not yet available.
rate_used=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
resets_at=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

if [ -n "$rate_used" ] && [ "$rate_used" != "null" ]; then
  rate_pct=$(printf '%.0f' "$rate_used")
  if [ "$rate_pct" -gt 80 ]; then
    rate_color="$RED"
  elif [ "$rate_pct" -ge 50 ]; then
    rate_color="$YELLOW"
  else
    rate_color="$GREEN"
  fi
  used_str=$(printf "${rate_color}used:%s%%${RESET}${DIM}" "$rate_pct")
else
  used_str="used:--"
fi

if [ -n "$resets_at" ] && [ "$resets_at" != "null" ]; then
  reset_time=$(date -r "$resets_at" +%H:%M 2>/dev/null)
  if [ -n "$reset_time" ]; then
    resets_str="resets:${reset_time}"
  else
    resets_str="resets:--"
  fi
else
  resets_str="resets:--"
fi

# Separator + right group always present, rendered fully dim
right_group=$(printf "${DIM}│  %s  %s${RESET}" "$used_str" "$resets_str")

# Build left group by joining non-empty parts with two spaces
left=""
for part in "$dir_part" "$model_part" "$ctx_part" "$duration_part" "$cost_part" "$branch_part" "$lines_part"; do
  if [ -n "$part" ]; then
    if [ -n "$left" ]; then
      left="$left  $part"
    else
      left="$part"
    fi
  fi
done

# Combine left and right groups
if [ -n "$left" ]; then
  printf '%s  %s' "$left" "$right_group"
else
  printf '%s' "$right_group"
fi
