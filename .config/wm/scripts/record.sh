#!/bin/sh
# Toggle screen recording (click an output or drag a region) to ~/Downloads, with desktop audio
pkill -INT -x wf-recorder && exit 0

dir="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
mkdir -p "$dir"
file="$dir/recording-$(date +%Y-%m-%d_%H-%M-%S).mp4"

geom=$(slurp -o) || exit 0
audio="$(wpctl inspect @DEFAULT_AUDIO_SINK@ | awk -F'"' '/ node\.name = / { print $2; exit }').monitor"

notify-send -t 1000 -a screenrec -i media-record-symbolic "Recording" "Super+Shift+R to stop"
sleep 1

wf-recorder -g "$geom" --audio="$audio" -f "$file" >/dev/null 2>&1
notify-send -a screenrec -i video-x-generic "Recording saved" "$file"
