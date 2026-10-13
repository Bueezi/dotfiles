#!/usr/bin/env bash
# Low-battery notifications at 30/20/10/5%. Exits right away on the desktop (no battery).

BAT="/sys/class/power_supply/BAT0"
[ -d "$BAT" ] || BAT="/sys/class/power_supply/BAT1"
[ -d "$BAT" ] || exit 0

last_level=100

while true; do
    cap=$(cat "$BAT/capacity")
    status=$(cat "$BAT/status")

    if [ "$status" = "Discharging" ]; then
        for level in 30 20 10 5; do
            if [ "$cap" -le "$level" ] && [ "$last_level" -gt "$level" ]; then
                urgency=$([ "$level" -le 10 ] && echo critical || echo normal)
                notify-send -u "$urgency" "Battery" "$level% remaining"
                break
            fi
        done
    fi

    last_level=$cap
    sleep 60
done
