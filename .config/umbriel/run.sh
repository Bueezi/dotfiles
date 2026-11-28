#!/bin/sh
# Umbriel keybind helpers: focus <app_id> <cmd...> | toggle <app_id> <cmd...> | fingers | game | hdr | slideshow
case "$1" in
focus)
    app=$2; shift 2
    id=$(umbriel windows --json | jq -r --arg a "$app" 'map(select(.app_id == $a)) | first | .id // empty')
    if [ -n "$id" ]; then exec umbriel msg window-focus "$id"; fi
    exec "$@" ;;
toggle)
    app=$2; shift 2
    id=$(umbriel windows --json | jq -r --arg a "$app" 'map(select(.app_id == $a and (.active | not))) | first | .id // empty')
    if [ -n "$id" ]; then exec umbriel msg window-focus "$id"; fi
    exec "$@" ;;
fingers)
    id=$(umbriel windows --json | jq -r 'map(select(.app_id == "org.gnome.eog" and .title == "fingers.svg")) | first | .id // empty')
    if [ -n "$id" ]; then exec umbriel msg window-close "$id"; fi
    exec eog ~/.config/umbriel/fingers.svg ;;
game)
    id=$(umbriel windows --json | jq -r 'map(select(.content_type == "game"
        or (.app_id | test("^steam_app_|^[Aa]ssetto[Cc]orsa\\.exe$|gamescope")))) | first | .id // empty')
    if [ -n "$id" ]; then exec umbriel msg window-focus "$id"; fi
    notify-send -a game -i input-gaming-symbolic "No game running" ;;
hdr)
    f=${XDG_STATE_HOME:-$HOME/.local/state}/umbriel/hdr.toml
    mkdir -p "${f%/*}"
    if grep -q '"on"' "$f" 2>/dev/null; then
        printf '[output.DP-2]\nhdr = "auto"\n' > "$f"
        notify-send -a hdr -i video-display-symbolic "HDR: auto" "On for fullscreen HDR content (games, video)"
    else
        printf '[output.DP-2]\nhdr = "on"\n' > "$f"
        notify-send -a hdr -i video-display-symbolic "HDR: on" "Always on"
    fi ;;
slideshow)
    if [ "$(noctalia msg config-get wallpaper.automation.enabled)" = true ]; then
        noctalia msg config-set wallpaper.automation.enabled false
        notify-send -a slideshow -i preferences-desktop-wallpaper-symbolic "Slideshow off"
    else
        noctalia msg config-set wallpaper.automation.enabled true
        noctalia msg wallpaper-random
        notify-send -a slideshow -i preferences-desktop-wallpaper-symbolic "Slideshow on" "A new wallpaper every 5 minutes"
    fi >/dev/null ;;
esac
