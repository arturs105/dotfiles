#!/bin/bash
# Mark tmux window as idle (Claude finished, awaiting input).
# Distinct from the permission_prompt path: visual hint only, no notifications.
[ -z "$TMUX" ] && exit 0
tmux set-option -w -t "$TMUX_PANE" @claude_attention 2 2>/dev/null
exit 0
