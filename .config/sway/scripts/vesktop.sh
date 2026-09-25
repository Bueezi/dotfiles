#!/bin/sh
# Focus Vesktop if it's open. Otherwise launch it: tiled on an empty workspace,
# floating if the workspace already has windows.

swaymsg -q '[app_id="vesktop"] focus' && exit 0

ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused).name')
windows=$(swaymsg -t get_tree | jq --arg ws "$ws" \
    '[.. | objects | select(.type? == "workspace" and .name == $ws) | .. | objects | select(.pid?)] | length')

if [ "$windows" -gt 0 ]; then
    # Float every Vesktop window that opens in the next 20s (splash + main window)
    timeout 20 swaymsg -m -t subscribe '["window"]' \
        | jq --unbuffered -r 'select(.change == "new" and .container.app_id == "vesktop") | .container.id' \
        | while read -r id; do
            swaymsg -q "[con_id=$id] floating enable, resize set 1200 800, move position center"
        done &
fi

exec vesktop
