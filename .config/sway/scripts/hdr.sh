#!/usr/bin/env bash

state="${XDG_RUNTIME_DIR:-/tmp}/sway-hdr"

if [ -f "$state" ]; then
    swaymsg output '*' hdr off
    rm -f "$state"
    notify-send "HDR off"
else
    swaymsg output '*' hdr on
    touch "$state"
    notify-send "HDR on"
fi
