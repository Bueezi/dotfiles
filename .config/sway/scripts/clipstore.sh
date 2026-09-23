#!/bin/sh
# Run by `wl-paste --watch` on every clipboard change. Browsers offer text/html
# *and* image/png for a copied picture; store the picture instead of the html.

case "$CLIPBOARD_STATE" in sensitive|clear) exec cliphist store ;; esac

img=$(wl-paste --list-types 2>/dev/null | grep -m1 '^image/')
if [ -n "$img" ]; then
    wl-paste --type "$img" | cliphist store
else
    exec cliphist store
fi
