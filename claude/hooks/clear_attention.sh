#!/bin/bash
# Attention updater for PreToolUse + UserPromptSubmit.
#   AskUserQuestion / ExitPlanMode  -> orange (1): Claude is blocked on YOUR
#       decision (same "needs input" meaning as a permission_prompt). These
#       tools fire only PreToolUse — no Stop, no Notification — so this is the
#       single chance to mark the window.
#   any other tool, or a fresh user prompt -> clear the marker: Claude is
#       actively working again.
[ -z "$TMUX" ] && exit 0
tool=$(cat | jq -r '.tool_name // empty' 2>/dev/null)
case "$tool" in
    AskUserQuestion|ExitPlanMode)
        tmux set-option -w -t "$TMUX_PANE" @claude_attention 1 2>/dev/null ;;
    *)
        tmux set-option -w -u -t "$TMUX_PANE" @claude_attention 2>/dev/null ;;
esac
exit 0
