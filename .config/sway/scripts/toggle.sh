#!/bin/sh
# Toggle a daemon that has a bar badge while it's stopped:
#   caffeine    stop swayidle so the screen never locks/blanks, or start it again (idle.sh)
#   nightlight  stop wlsunset (neutral colours), or start it again (sunset.sh)
# Usage: toggle.sh caffeine|nightlight          toggle
#        toggle.sh caffeine|nightlight status   print the bar badge JSON (for i3status-rs)

case "$1" in
caffeine)
    proc=swayidle start=idle.sh signal=1 badge="󰅶 caffeine"
    stopped="Caffeine on|Screen will stay awake" started="Caffeine off|Idle lock restored" ;;
nightlight)
    proc=wlsunset start=sunset.sh signal=2 badge="󰖨 no nightlight"
    stopped="Night light off|Colours are neutral" started="Night light on|wlsunset restored" ;;
*)
    echo "usage: $0 caffeine|nightlight [status]" >&2; exit 1 ;;
esac

if [ "$2" = status ]; then
    # A highlighted (Critical = inverted colours) badge while stopped, empty text (block
    # hidden) otherwise
    if pgrep -x $proc >/dev/null; then
        echo '{"text": ""}'
    else
        echo "{\"text\": \"$badge\", \"state\": \"Critical\"}"
    fi
    exit 0
fi

if pgrep -x $proc >/dev/null; then
    pkill -x $proc
    notify-send -t 1500 -a "$1" -i weather-clear-symbolic "${stopped%|*}" "${stopped#*|}"
else
    setsid -f "$(dirname "$0")/$start" >/dev/null 2>&1
    notify-send -t 1500 -a "$1" -i weather-clear-night-symbolic "${started%|*}" "${started#*|}"
fi

# Refresh the bar block (match the command line: on NixOS the process is named ".i3status-rs-wr")
pkill -RTMIN+$signal -f '^[^ ]*/i3status-rs( |$)'
