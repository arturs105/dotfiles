#!/usr/bin/env bash
# Status line: cwd, git branch, user@host, context-window usage.
#
# Context usage comes from Claude Code's native `context_window` field in the
# status-line JSON input (Claude Code >= 2.1.x). `total_input_tokens` already
# folds in cache reads/writes and reflects *current* context occupancy.
#
# Before the first API response of a session that field is empty, so the
# baseline (system prompt + tools + skills + custom instructions) isn't yet
# known to the status line. We cache the first total observed per project and
# show it as an approximate "~16k" until the live number is available. The
# baseline is refreshed once per session (keyed by session_id), so it tracks
# changes to CLAUDE.md / skills / MCP without drifting upward as a session grows.
#
# Width handling: the status-line command runs with no controlling tty, so
# $COLUMNS and `tput cols` don't work. Inside tmux we read the pane width via
# `tmux display-message -t "$TMUX_PANE"` (served over the tmux socket, no tty
# needed) and wrap the user@host + context segment onto a second line when the
# single line wouldn't fit the pane (e.g. narrow vertical splits).

input=$(cat)

cwd=$(jq -r '.workspace.current_dir // empty' <<<"$input")
proj=$(jq -r '.workspace.project_dir // .workspace.current_dir // empty' <<<"$input")
model_id=$(jq -r '.model.id // empty' <<<"$input")
session_id=$(jq -r '.session_id // empty' <<<"$input")

# --- git ---------------------------------------------------------------
git_info=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [[ -n "$branch" ]]; then
    if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null \
      || ! git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null; then
      dirty="*"
    else
      dirty=""
    fi
    git_info=" ($branch$dirty)"
  fi
fi

user=$(whoami)
host=$(hostname -s)

# --- context window ----------------------------------------------------
# Prefer total_input_tokens; fall back to summing current_usage for safety.
tokens=$(jq -r '
  .context_window as $c
  | (($c.total_input_tokens // 0) | floor) as $t
  | if $t > 0 then $t
    else (($c.current_usage.input_tokens // 0)
          + ($c.current_usage.cache_read_input_tokens // 0)
          + ($c.current_usage.cache_creation_input_tokens // 0) | floor)
    end
' <<<"$input")
window=$(jq -r '(.context_window.context_window_size // 0) | floor' <<<"$input")

# Fall back when the native window size is absent: 1M-context models carry a
# [1m] suffix on the id, otherwise assume 200k (auto-bump if usage exceeds it).
if [[ -z "$window" || "$window" == "null" || "$window" -le 0 ]]; then
  if [[ "$model_id" == *"[1m]"* || "${tokens:-0}" -gt 200000 ]]; then
    window=1000000
  else
    window=200000
  fi
fi

# Per-project baseline cache so the HUD is populated before the first prompt.
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
proj_key=$(printf '%s' "${proj:-$cwd}" | tr -c 'A-Za-z0-9' '_')
cache_file="$cache_dir/$proj_key"

approx=""
if [[ "${tokens:-0}" =~ ^[0-9]+$ && "$tokens" -gt 0 ]]; then
  # Live data available. Record this session's first observed total as next
  # session's baseline — written once per session id, before context grows.
  cached_session=""
  [[ -f "$cache_file" ]] && read -r cached_session _ _ <"$cache_file" 2>/dev/null
  if [[ "$cached_session" != "$session_id" ]]; then
    mkdir -p "$cache_dir" 2>/dev/null \
      && printf '%s %s %s\n' "$session_id" "$tokens" "$window" >"$cache_file" 2>/dev/null
  fi
elif [[ -f "$cache_file" ]]; then
  # No live data yet (pre-prompt). Fall back to the cached baseline, marked ~.
  read -r _ tokens window <"$cache_file" 2>/dev/null
  approx="~"
fi

# --- format context segment -------------------------------------------
if [[ "${tokens:-0}" =~ ^[0-9]+$ && "$tokens" -gt 0 ]]; then
  pct=$(awk -v t="$tokens" -v w="$window" 'BEGIN{printf "%.0f", (t/w)*100}')
  if [[ "$tokens" -ge 1000000 ]]; then
    tk=$(awk -v t="$tokens" 'BEGIN{printf "%.1fM", t/1000000}')
  elif [[ "$tokens" -ge 1000 ]]; then
    tk=$(awk -v t="$tokens" 'BEGIN{printf "%.0fk", t/1000}')
  else
    tk="$tokens"
  fi
  ctx_str=$(printf "[%s%s|%s%%]" "$approx" "$tk" "$pct")
else
  ctx_str="[--|0%]"
fi

# --- layout / wrapping -------------------------------------------------
# Plain (uncolored) length drives the wrap decision.
single_plain="$cwd$git_info $user@$host $ctx_str"

# Pane width via tmux (no tty needed); 0 = unknown -> stay on one line.
width=0
if [[ -n "$TMUX_PANE" ]]; then
  w=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_width}' 2>/dev/null)
  [[ "$w" =~ ^[0-9]+$ ]] && width="$w"
fi

C_CWD=$'\033[38;5;32m'
C_GIT=$'\033[38;5;75m'
C_HOST=$'\033[38;5;245m'
C_CTX=$'\033[38;5;214m'
C_RST=$'\033[0m'

# Wrap with a 1-col margin to avoid the terminal's own mid-token wrap.
if [[ "$width" -gt 0 && "${#single_plain}" -gt $((width - 1)) ]]; then
  printf '%s%s%s%s%s\n%s%s@%s%s %s%s%s' \
    "$C_CWD" "$cwd" "$C_GIT" "$git_info" "$C_RST" \
    "$C_HOST" "$user" "$host" "$C_RST" "$C_CTX" "$ctx_str" "$C_RST"
else
  printf '%s%s%s%s%s %s%s@%s%s %s%s%s' \
    "$C_CWD" "$cwd" "$C_GIT" "$git_info" "$C_RST" \
    "$C_HOST" "$user" "$host" "$C_RST" "$C_CTX" "$ctx_str" "$C_RST"
fi
