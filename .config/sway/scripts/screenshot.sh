#!/bin/sh
# Region screenshot to the clipboard. wayfreeze covers the screen with a still image first,
# so video/animations stand still while you select; Esc in slurp cancels.
exec wayfreeze --hide-cursor --after-freeze-cmd '
    g=$(slurp) && grim -g "$g" - | wl-copy && notify-send "Screenshot in clipboard"
    pkill -x wayfreeze'
