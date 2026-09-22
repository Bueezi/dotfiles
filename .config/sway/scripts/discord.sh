#!/usr/bin/env bash

# If Discord window already exists, float and focus it immediately
if swaymsg '[class="discord"] floating enable, resize set 1400 900, move position center, focus' 2>/dev/null; then
    exit 0
fi

# Launch Discord and wait for the actual window (skip the updater)
discord &

until swaymsg '[class="discord"] floating enable, resize set 1400 900, move position center, focus' 2>/dev/null; do
    sleep 0.3
done
