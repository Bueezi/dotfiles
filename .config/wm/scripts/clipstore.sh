#!/bin/sh
# Stores every clipboard change in cliphist (clipboard.sh shows the history). Browsers offer
# text/html *and* image/png for a copied picture; store the picture instead of the html.
# Everything has a timeout: a transfer from a client that died mid-copy would otherwise hang
# forever, and the stuck `cliphist store` keeps the history db locked for every later copy.
# Sway: run by `wl-paste --watch` on every change. i3 (X11, the tablet): started once, waits
# for each change with clipnotify (X11 has no `wl-paste --watch`). It also fires when text is only
# highlighted (no `-s clipboard` in older versions): that re-stores the same clipboard, which cliphist
# just moves to the top.

if [ -n "$SWAYSOCK" ]; then
    case "$CLIPBOARD_STATE" in sensitive|clear) exec timeout 10 cliphist store ;; esac

    img=$(timeout 5 wl-paste --list-types 2>/dev/null | grep -m1 '^image/')
    if [ -n "$img" ]; then
        timeout 10 wl-paste --type "$img" | timeout 10 cliphist store
    else
        exec timeout 10 cliphist store
    fi
    exit
fi

while clipnotify; do
    img=$(timeout 5 xclip -selection clipboard -o -t TARGETS 2>/dev/null | grep -m1 '^image/')
    if [ -n "$img" ]; then
        timeout 10 xclip -selection clipboard -o -t "$img" | timeout 10 cliphist store
    else
        timeout 10 xclip -selection clipboard -o | timeout 10 cliphist store
    fi
done
