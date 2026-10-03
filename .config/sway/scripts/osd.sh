#!/bin/sh
# Media/brightness keys with a short-lived notification that replaces itself.
# Usage: osd.sh volume up|down|mute | mic mute | brightness up|down|status | media play|next|prev

id_file="${XDG_RUNTIME_DIR:-/tmp}/osd-notify-id"

# notify <icon> <text> [percent]
# The level is drawn as a 25-char text bar (█ filled, ░ empty, 4% each) instead of mako's coloured progress bar
notify() {
    # Empty or garbage (a half-written file, a failed run): start a new popup instead of failing
    id=$(cat "$id_file" 2>/dev/null)
    case "$id" in ''|*[!0-9]*) id=0 ;; esac
    bar=
    if [ -n "$3" ]; then
        filled=$(( ($3 + 2) / 4 ))
        i=0
        while [ $i -lt 25 ]; do
            if [ $i -lt $filled ]; then bar="$bar█"; else bar="$bar░"; fi
            i=$((i + 1))
        done
    fi
    # Written via a temp file + mv: a plain `> "$id_file"` empties it first, and another press
    # reading it at that moment got "" and broke the OSD for good
    new=$(notify-send -p -r "$id" -t 1000 -u low -a osd -i "$1" "$2" "$bar") &&
        printf '%s\n' "$new" > "$id_file.$$" && mv -f "$id_file.$$" "$id_file"
}

volume() {
    out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)   # "Volume: 0.40" or "Volume: 0.40 [MUTED]"
    vol=$(echo "$out" | awk '{ printf "%d", $2 * 100 + 0.5 }')
    if echo "$out" | grep -q MUTED; then
        notify audio-volume-muted-symbolic "Muted" "$vol"
    else
        notify audio-volume-high-symbolic "Volume $vol%" "$vol"
    fi
}

# No backlight (desktop): the monitor's own brightness over DDC/CI (VCP 0x10).
# A ddcutil call takes ~0.1s, so the level is kept in a file: the OSD shows at once
# and one background job pushes the newest level to the monitor (presses coalesce).
dir="${XDG_RUNTIME_DIR:-/tmp}"
bus_file="$dir/osd-ddc-bus" level_file="$dir/osd-ddc-level"

# ddc_level <max age s>: the level into $cur, re-read from the monitor when the file is older
# (it may have been changed with its own buttons). Takes the level lock (fd 8).
ddc_level() {
    [ -s "$bus_file" ] || ddcutil detect --brief | sed -n 's|.*/dev/i2c-||p' | head -1 > "$bus_file"
    bus=$(cat "$bus_file")
    exec 8>"$dir/osd-ddc-level.lock"
    flock 8
    if [ ! -s "$level_file" ] || [ $(( $(date +%s) - $(stat -c %Y "$level_file") )) -gt "$1" ]; then
        ddcutil --bus "$bus" -t getvcp 10 | awk '{ print $4 }' > "$level_file"
    fi
    cur=$(cat "$level_file")
    [ -n "$cur" ] || { rm -f "$bus_file" "$level_file"; exit 1; }
}

# brightness +|-  (5% steps)
brightness() {
    if [ -n "$(ls /sys/class/backlight 2>/dev/null)" ]; then
        b=$(brightnessctl -m set "5%$1" | cut -d, -f4 | tr -d %)
    else
        ddc_level 10
        b=$(( cur $1 5 ))
        [ "$b" -lt 0 ] && b=0
        [ "$b" -gt 100 ] && b=100
        echo "$b" > "$level_file"
        exec 8>&-

        apply() {
            while :; do
                flock -n 9 || return 0   # an applier is already running and will send our level
                sent=
                while [ "$(cat "$level_file")" != "$sent" ]; do
                    sent=$(cat "$level_file")
                    ddcutil --bus "$bus" --noverify setvcp 10 "$sent"
                done
                flock -u 9
                # A press that landed while unlocking couldn't start its own applier
                [ "$(cat "$level_file")" = "$sent" ] && return 0
            done
        }
        ( apply ) 9>"$dir/osd-ddc.lock" &
        # The bar's DDC brightness block (signal = 3; on NixOS the process is ".i3status-rs-wr")
        pkill -RTMIN+3 -f '^[^ ]*/i3status-rs( |$)'
    fi
    notify display-brightness-symbolic "Brightness $b%" "$b"
}

case "$1 $2" in
    "volume up")       wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+; volume ;;
    "volume down")     wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-;        volume ;;
    "volume mute")     wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle;       volume ;;
    "mic mute")
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
            notify microphone-sensitivity-muted-symbolic "Mic muted"
        else
            notify audio-input-microphone-symbolic "Mic on"
        fi ;;
    "brightness up")   brightness + ;;
    "brightness down") brightness - ;;
    # For the bar (i3status.toml), desktop only: the laptop has the backlight block
    "brightness status")
        [ -n "$(ls /sys/class/backlight 2>/dev/null)" ] && exit 0
        ddc_level 60
        echo "$cur%" ;;
    "media play"|"media next"|"media prev")
        case "$2" in play) playerctl play-pause ;; next) playerctl next ;; prev) playerctl previous ;; esac
        sleep 0.2  # give the player time to update its metadata
        status=$(playerctl status 2>/dev/null) || exit 0
        track=$(playerctl metadata --format '{{artist}} – {{title}}' 2>/dev/null)
        icon=media-playback-start-symbolic
        [ "$status" = Paused ] && icon=media-playback-pause-symbolic
        notify "$icon" "${track:-$status}" ;;
esac
