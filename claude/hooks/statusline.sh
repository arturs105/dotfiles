#!/usr/bin/env bash
# Status line: cwd, git branch, user@host, context-window usage.
# Token usage is parsed from the session transcript because Claude Code's
# status-line input does not expose it directly.

input=$(cat)

cwd=$(jq -r '.workspace.current_dir' <<<"$input")
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
model_id=$(jq -r '.model.id // empty' <<<"$input")

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

ctx_str=""
if [[ -n "$transcript" && -f "$transcript" ]]; then
  last_usage=$(grep '"usage"' "$transcript" 2>/dev/null | tail -1)
  if [[ -n "$last_usage" ]]; then
    tokens=$(jq -r '
      .message.usage
      | (.input_tokens // 0)
        + (.cache_read_input_tokens // 0)
        + (.cache_creation_input_tokens // 0)
    ' <<<"$last_usage" 2>/dev/null)

    if [[ -n "$tokens" && "$tokens" != "null" && "$tokens" -gt 0 ]]; then
      # 1M-context models carry a [1m] suffix; otherwise assume 200k.
      # Auto-bump if measured usage already exceeds 200k.
      if [[ "$model_id" == *"[1m]"* || "$tokens" -gt 200000 ]]; then
        window=1000000
      else
        window=200000
      fi

      pct=$(awk -v t="$tokens" -v w="$window" 'BEGIN{printf "%.0f", (t/w)*100}')

      if [[ "$tokens" -ge 1000000 ]]; then
        tk=$(awk -v t="$tokens" 'BEGIN{printf "%.1fM", t/1000000}')
      elif [[ "$tokens" -ge 1000 ]]; then
        tk=$(awk -v t="$tokens" 'BEGIN{printf "%.0fk", t/1000}')
      else
        tk="$tokens"
      fi

      ctx_str=$(printf " [%s|%s%%]" "$tk" "$pct")
    fi
  fi
fi

printf "\033[38;5;32m%s\033[38;5;75m%s\033[0m \033[38;5;245m%s@%s\033[38;5;214m%s\033[0m" \
  "$cwd" "$git_info" "$user" "$host" "$ctx_str"
