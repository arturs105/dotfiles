#!/bin/bash
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
notification_type=$(echo "$input" | jq -r '.notification_type')
session_id=$(echo "$input" | jq -r '.session_id')
project=$(basename "$cwd")

# Does this notification mean "Claude is blocked, needs your input" (→ orange)?
#   permission_prompt  - tool or plan approval needed
#   elicitation_dialog - MCP server asking for input
#   idle_prompt        - "Claude is waiting for your input". This is the only
#                        signal that still fires under auto permission mode, but
#                        it also fires after a clean end-of-turn idle. So only
#                        treat it as needs-input when the Stop hook hasn't
#                        already marked the window idle (green = 2); a turn that
#                        simply finished should stay green.
needs_input=0
case "$notification_type" in
    permission_prompt|elicitation_dialog)
        needs_input=1 ;;
    idle_prompt)
        cur=$(tmux show-options -wv -t "$TMUX_PANE" @attention 2>/dev/null)
        [ "$cur" = "2" ] || needs_input=1 ;;
esac

# Mark tmux window orange (needs attention). Visual hint only, so it runs even
# when desktop/phone notifications are silenced (off-switch is below).
if [ "$needs_input" = 1 ] && [ -n "$TMUX" ]; then
    tmux set-option -w -t "$TMUX_PANE" @attention 1 2>/dev/null
fi

# Non-blocking notifications (auth_success, idle-while-already-green,
# elicitation_complete/response, …) get no colour change and no ping.
[ "$needs_input" = 1 ] || exit 0

# Hard off-switch for pings (the tmux colour above still applies)
[ -f ~/.claude/notify-off ] && exit 0

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
