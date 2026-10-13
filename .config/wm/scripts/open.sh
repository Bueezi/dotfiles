#!/bin/sh
# Open or toggle an app: tiled (all the space) on an empty workspace, floating (w×h, centred,
# as a scratchpad window so $mod+minus hides it) when the workspace already has windows. Pressing the key again while it's focused hides it
# to the scratchpad; the next press brings it back, placed the same way.
# The app's window is found by a sway mark, set by a for_window rule in the sway config.
# Usage: open.sh <mark> <width> <height> <command...>

mark=$1 w=$2 h=$3
shift 3

tree=$(swaymsg -t get_tree)
ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused).name')
win=$(echo "$tree" | jq -c --arg m "$mark" \
    'first(.. | objects | select((.marks? // []) | index($m))) | { focused, scratchpad_state, visible }' 2>/dev/null)
# Other windows on this workspace
others=$(echo "$tree" | jq --arg ws "$ws" --arg m "$mark" \
    '[.. | objects | select(.type? == "workspace" and .name == $ws) | .. | objects
      | select(.pid? and ((.marks // []) | index($m) | not))] | length')

# Always onto this workspace: sway would otherwise put the window where the app was
# first started (e.g. the workspace you were on at login for autostarted apps)
place() {
    here="[con_mark=\"^$mark\$\"] move container to workspace \"$ws\"; workspace \"$ws\"; [con_mark=\"^$mark\$\"]"
    if [ "$others" -eq 0 ]; then
        swaymsg -q "$here floating disable, focus"
    else
        swaymsg -q "$here move scratchpad, scratchpad show, resize set $w $h, move position center, focus"
    fi
}

if [ -z "$win" ]; then
    # Not open: launch, and place the window once the for_window rule has marked it
    timeout 30 swaymsg -m -t subscribe '["window"]' \
        | jq --unbuffered -r --arg m "$mark" \
            'select(.change == "mark" and ((.container.marks // []) | index($m))) | "x"' \
        | { read -r _ && place; } &
    exec "$@"
elif [ "$(echo "$win" | jq -r '.focused and .visible')" = true ]; then
    swaymsg -q "[con_mark=\"^$mark\$\"] move scratchpad"
else
    # Hidden in the scratchpad, or open somewhere else: bring it here
    [ "$(echo "$win" | jq -r '.visible')" = false ] && swaymsg -q "[con_mark=\"^$mark\$\"] scratchpad show"
    place
fi
