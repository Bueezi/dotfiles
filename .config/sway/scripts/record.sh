#!/bin/sh
# Toggle screen recording. Click an output for fullscreen, drag for a region, Esc to cancel.
# Saves to ~/Downloads with desktop audio.

# Already recording? Stop it (the running instance below sends the "saved" notification).
pkill -INT -x wf-recorder && exit 0

dir="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
mkdir -p "$dir"
file="$dir/recording-$(date +%Y-%m-%d_%H-%M-%S).mp4"

geom=$(slurp -o) || exit 0
audio="$(pactl get-default-sink).monitor"   # what you hear, not the mic

notify-send -t 1000 -a screenrec -i media-record-symbolic "Recording" "Super+Shift+R to stop"
sleep 1   # let the notification vanish before capture starts

wf-recorder -g "$geom" --audio="$audio" -f "$file" >/dev/null 2>&1
notify-send -a screenrec -i video-x-generic "Recording saved" "$file"
