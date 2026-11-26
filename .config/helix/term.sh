#!/bin/sh
# Hidden in a window of its own, so it keeps running. $1 = folder for a new one
# run <file> [ask]: helix/run.sh in a pane below, reused on the next run
hx=$TMUX_PANE dir=$1
if [ "$1" = run ]; then
    shift
    p=$(tmux list-panes -t "$hx" -F '#{pane_id} #{@hxrun}' | awk -v h="$hx" '$2 == h { print $1; exit }')
    if [ -n "$p" ]; then
        tmux respawn-pane -k -t "$p" sh ~/.config/helix/run.sh "$@" \; select-pane -t "$p"
    else
        p=$(tmux split-window -v -l 40% -t "$hx" -P -F '#{pane_id}' sh ~/.config/helix/run.sh "$@")
        tmux set -p -t "$p" @hxrun "$hx"
    fi
    exit
fi
set -- $(tmux list-panes -s -t "$hx" -F '#{pane_id} #{window_id} #{@hxterm}' | awk -v h="$hx" '$3 == h { print $1, $2; exit }')
if [ -z "$1" ]; then
    p=$(tmux split-window -v -l 15 -t "$hx" -c "$dir" -P -F '#{pane_id}')
    tmux set -p -t "$p" @hxterm "$hx"
elif [ "$2" = "$(tmux display -p -t "$hx" '#{window_id}')" ]; then
    tmux break-pane -d -n hxterm -s "$1"
else
    tmux join-pane -v -l 15 -s "$1" -t "$hx"
fi
