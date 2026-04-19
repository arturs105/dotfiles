#!/bin/bash
# Capture Terminal.app window ID at session start for later notification focusing

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id')

# Get the front Terminal window ID
window_id=$(osascript -e 'tell application "Terminal" to return id of front window' 2>/dev/null)

if [[ -n "$session_id" && -n "$window_id" ]]; then
    mkdir -p ~/.claude/session-windows
    echo "$window_id" > ~/.claude/session-windows/"$session_id"
fi
