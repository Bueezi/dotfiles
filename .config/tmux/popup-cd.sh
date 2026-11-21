#!/bin/sh
# popup-cd.sh <session id> <folder>: moves that session's pop-up there if it's at a fish prompt
t="=popup-${1#\$}:"
[ "$(tmux display -p -t "$t" '#{pane_current_command}' 2>/dev/null)" = fish ] || exit 0
[ "$(tmux display -p -t "$t" '#{pane_current_path}')" = "$2" ] && exit 0
tmux send-keys -t "$t" -l " cd '$(printf %s "$2" | sed "s/[\\\\']/\\\\&/g")'" \; send-keys -t "$t" Enter
