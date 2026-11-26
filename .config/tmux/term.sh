#!/bin/sh
# Shell pane below pane $2, hidden in a window of its own so it keeps running.
# toggle <pane> <dir>  |  run <pane> <file> [ask]
mode=$1 me=$2; shift 2
own=$(tmux display -p -t "$me" '#{@hxterm}')
if [ -n "$own" ]; then
    [ "$mode" = toggle ] && tmux break-pane -d -n hxterm -s "$me" \; select-pane -t "$own"
    exit 0
fi
q() { printf "'%s'" "$(printf %s "$1" | sed "s/[\\\\']/\\\\&/g")"; }
# Leading space: fish keeps it out of history
[ "$mode" = run ] && cmd=" clear; sh ~/.config/helix/run.sh $(q "$1") $2"
read -r p w <<EOF
$(tmux list-panes -s -t "$me" -F '#{pane_id} #{window_id} #{@hxterm}' | awk -v h="$me" '$3 == h { print $1, $2; exit }')
EOF
if [ -z "$p" ]; then
    dir=$1; [ "$mode" = run ] && dir=$(dirname "$1")
    p=$(tmux split-window -v -l 15 -t "$me" -c "$dir" -P -F '#{pane_id}' ${cmd:+fish -C "functions -e fish_greeting;$cmd"})
    exec tmux set -p -t "$p" @hxterm "$me"
elif [ "$w" != "$(tmux display -p -t "$me" '#{window_id}')" ]; then
    tmux join-pane -v -l 15 -s "$p" -t "$me"
elif [ "$mode" = toggle ]; then
    exec tmux break-pane -d -n hxterm -s "$p"
fi
[ "$mode" = run ] || exit 0
tmux select-pane -t "$p"
if [ "$(tmux display -p -t "$p" '#{pane_current_command}')" != fish ]; then
    exec tmux display-message "Terminal busy: stop what runs there first"
fi
tmux send-keys -t "$p" "$cmd" Enter
