#!/bin/bash
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
notification_type=$(echo "$input" | jq -r '.notification_type')
session_id=$(echo "$input" | jq -r '.session_id')
project=$(basename "$cwd")

# Hard off-switch
[ -f ~/.claude/notify-off ] && exit 0

# Mark tmux window as needing attention
if [ -n "$TMUX" ]; then
    tmux set-option -w -t "$TMUX_PANE" @claude_attention 1 2>/dev/null
fi

# Presence check: away = locked OR idle > 10 min
idle=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
locked=$(ioreg -n Root -d1 -a | grep -c CGSSessionScreenIsLocked)

if [ "$locked" -gt 0 ] || [ "$idle" -gt 600 ]; then
    # Away → phone only
    NTFY_TOPIC="claude-artur-9f3k2"  # TODO: set to your ntfy topic
    curl -s \
        -H "Title: Claude: $project" \
        -d "$notification_type" \
        "ntfy.sh/$NTFY_TOPIC" >/dev/null
else
    # Present → desktop only
    window_id=""
    if [[ -f ~/.claude/session-windows/"$session_id" ]]; then
        window_id=$(cat ~/.claude/session-windows/"$session_id")
    fi

    if [[ -n "$window_id" ]]; then
        activate_cmd="osascript -e 'tell application \"Terminal\" to activate' -e 'tell application \"Terminal\" to set index of window id $window_id to 1'"
    else
        activate_cmd="osascript -e 'tell application \"Terminal\" to activate'"
    fi

    terminal-notifier \
        -title "Claude: $project" \
        -message "$notification_type" \
        -execute "$activate_cmd"
fi
