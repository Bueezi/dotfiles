#!/usr/bin/env bash
# Display switcher: extend / mirror / single screen, picked with fuzzel.
# Needs: jq, wl-mirror

internal="eDP-1"
outputs=$(swaymsg -t get_outputs -r)

external=$(jq -r --arg i "$internal" '.[] | select(.name != $i) | .name' <<< "$outputs" | head -n1)
if [ -z "$external" ]; then
    pkill -x wl-mirror
    swaymsg output "$internal" enable mode 2160x1440 scale 1.35
    notify-send "Display" "No external display, laptop screen restored"
    exit 0
fi

choice=$(printf "extend right\nextend left\nmirror\nexternal only\nlaptop only" |
    fuzzel --dmenu --prompt "display ❯ " --lines 5 --width 22)
[ -z "$choice" ] && exit 0

# Stop any running mirror before changing layout
pkill -x wl-mirror

width_of() {
    swaymsg -t get_outputs -r | jq -r --arg o "$1" '.[] | select(.name == $o) | .rect.width'
}

case "$choice" in
    "extend right")
        swaymsg output "$internal" enable pos 0 0
        swaymsg output "$external" enable pos "$(width_of "$internal")" 0
        ;;
    "extend left")
        swaymsg output "$external" enable pos 0 0
        swaymsg output "$internal" enable pos "$(width_of "$external")" 0
        ;;
    "mirror")
        swaymsg output "$internal" enable mode 1920x1080 scale 1.25 pos 0 0
        swaymsg output "$external" enable pos "$(width_of "$internal")" 0
        wl-mirror --fullscreen-output "$external" "$internal" &
        ;;
    "external only")
        swaymsg output "$external" enable
        swaymsg output "$internal" disable
        ;;
    "laptop only")
        swaymsg output "$internal" enable
        swaymsg output "$external" disable
        ;;
esac

notify-send "Display" "$choice"
