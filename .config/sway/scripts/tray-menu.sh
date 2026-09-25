#!/bin/sh
# Tray right-click menus from Electron apps (Vesktop, LM Studio, Claude...) open as plain
# windows with no app_id and no title. A for_window rule in the sway config floats them
# before they're drawn and parks them off-screen; this moves each one into the top-right
# corner of the focused output, under the bar (a rule can't right-align a variable width).

bar=20      # bar height (bar { height } in the sway config)
gap=5
border=2    # default_border pixel 2

log="${XDG_RUNTIME_DIR:-/tmp}/tray-menu.log"
: > "$log"

swaymsg -m -t subscribe '["window"]' \
    | jq --unbuffered -r '
        select(.change == "new") | .container
        | select(.shell == "xdg_shell" and (.app_id // "") == "" and (.name // "") == "")
        | .id' \
    | while read -r id; do
        size() {
            swaymsg -t get_tree | jq -r --argjson id "$id" \
                '.. | objects | select(.id? == $id) | "\(.geometry.width) \(.geometry.height)"'
        }
        set -- $(size)
        # Retry once if the menu hasn't reported a sane size yet
        { [ "${1:-0}" -gt 0 ] && [ "${2:-0}" -gt 0 ] && [ "$2" -lt 1000 ]; } || { sleep 0.1; set -- $(size); }
        w=${1:-0} h=${2:-0}
        { [ "$w" -gt 0 ] && [ "$h" -gt 0 ] && [ "$h" -lt 1000 ]; } || { w=250; h=300; }
        set -- $(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | "\(.rect.x) \(.rect.y) \(.rect.width)"')
        x=$(( $1 + $3 - w - 2 * border - gap ))
        y=$(( $2 + bar + gap ))
        echo "con $id: ${w}x$h at $x,$y" >> "$log"
        swaymsg -q "[con_id=$id] resize set $w $h, move absolute position $x $y"
    done
