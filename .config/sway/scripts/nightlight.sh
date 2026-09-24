#!/bin/sh
# Toggle the night light: stop wlsunset (neutral colours) or start it again.
# Usage: nightlight.sh          toggle
#        nightlight.sh status   print the bar badge JSON (for i3status-rs)

if [ "$1" = status ]; then
    # JSON for i3status-rs: a highlighted (Critical = inverted colours) badge while
    # the night light is off, empty text (block hidden) otherwise
    if pgrep -x wlsunset >/dev/null; then
        echo '{"text": ""}'
    else
        echo '{"text": "󰖨 no nightlight", "state": "Critical"}'
    fi
    exit 0
fi

if pgrep -x wlsunset >/dev/null; then
    pkill -x wlsunset
    notify-send -t 1500 -a nightlight -i weather-clear-symbolic "Night light off" "Colours are neutral"
else
    setsid -f "$(dirname "$0")/sunset.sh" >/dev/null 2>&1
    notify-send -t 1500 -a nightlight -i weather-clear-night-symbolic "Night light on" "wlsunset restored"
fi

# Refresh the i3status-rs nightlight block (signal = 2)
# (match the command line: on NixOS the process is named ".i3status-rs-wr")
pkill -RTMIN+2 -f '^[^ ]*/i3status-rs( |$)'
