#!/bin/bash
[ -z "$TMUX" ] && exit 0
tmux set-option -w -u -t "$TMUX_PANE" @claude_attention 2>/dev/null
exit 0
