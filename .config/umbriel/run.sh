#!/bin/sh
# Helpers for Umbriel's keybinds (./config.toml).
#   run.sh focus <app_id> <command...>  focus a window of <app_id> (from the scratchpad too), else run <command>
#   run.sh hdr                          DP-2's HDR: "auto" (only for fullscreen HDR content) <-> "on"
#                                       (always). In a state file the config includes, so it stays as is
case "$1" in
focus)
    app=$2; shift 2
    id=$(umbriel windows --json | jq -r --arg a "$app" 'map(select(.app_id == $a)) | first | .id // empty')
    if [ -n "$id" ]; then exec umbriel msg window-focus "$id"; fi
    exec "$@" ;;
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
esac
