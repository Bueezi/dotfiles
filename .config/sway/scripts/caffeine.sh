#!/bin/sh
# Toggle caffeine: stop swayidle so the screen never locks/blanks, or start it again.
# Usage: caffeine.sh          toggle
#        caffeine.sh status   print the bar badge JSON (for i3status-rs)

if [ "$1" = status ]; then
    # JSON for i3status-rs: a highlighted (Critical = inverted colours) badge while
    # caffeinated, empty text (block hidden) otherwise
    if pgrep -x swayidle >/dev/null; then
        echo '{"text": ""}'
    else
        echo '{"text": "󰅶 caffeine", "state": "Critical"}'
    fi
    exit 0
fi

if pgrep -x swayidle >/dev/null; then
    pkill -x swayidle
    notify-send -t 1500 -a caffeine -i weather-clear-symbolic "Caffeine on" "Screen will stay awake"
else
    setsid -f "$(dirname "$0")/idle.sh" >/dev/null 2>&1
    notify-send -t 1500 -a caffeine -i weather-clear-night-symbolic "Caffeine off" "Idle lock restored"
fi

# Refresh the i3status-rs caffeine block (signal = 1)
# (match the command line: on NixOS the process is named ".i3status-rs-wr")
pkill -RTMIN+1 -f '^[^ ]*/i3status-rs( |$)'
