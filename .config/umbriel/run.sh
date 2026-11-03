#!/bin/sh
# Helpers for Umbriel's keybinds (./config.toml).
#   run.sh focus <app_id> <command...>  focus a window of <app_id> (from the scratchpad too), else run <command>
#   run.sh toggle <app_id> <command...> for apps that show/hide themselves when run again (ytmusic): shown
#                                       but not focused, focus it (the app can't take focus itself on
#                                       Wayland); else run <command>, which shows or hides it
#   run.sh game                         focus the running game: Steam's (steam_app_<id>), AC, gamescope (CS2),
#                                       anything tagged a game
#   run.sh hdr                          DP-2's HDR: "auto" (only for fullscreen HDR content) <-> "on"
#                                       (always). In a state file the config includes, so it stays as is
#   run.sh slideshow                    Noctalia's wallpaper rotation on/off: a random one every 5 minutes
#                                       (folder and interval: ~/.config/noctalia/config.toml)
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
        noctalia msg wallpaper-random   # a new one now: the rotation waits its first interval
        notify-send -a slideshow -i preferences-desktop-wallpaper-symbolic "Slideshow on" "A new wallpaper every 5 minutes"
    fi >/dev/null ;;
esac
