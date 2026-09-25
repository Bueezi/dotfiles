#!/bin/sh
# Run by `wl-paste --watch` on every clipboard change. Browsers offer text/html
# *and* image/png for a copied picture; store the picture instead of the html.
# Everything has a timeout: a transfer from a client that died mid-copy would otherwise hang
# forever, and the stuck `cliphist store` keeps the history db locked for every later copy.

case "$CLIPBOARD_STATE" in sensitive|clear) exec timeout 10 cliphist store ;; esac

img=$(timeout 5 wl-paste --list-types 2>/dev/null | grep -m1 '^image/')
if [ -n "$img" ]; then
    timeout 10 wl-paste --type "$img" | timeout 10 cliphist store
else
    exec timeout 10 cliphist store
fi
