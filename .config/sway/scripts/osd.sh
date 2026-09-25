#!/bin/sh
# Media/brightness keys with a short-lived notification that replaces itself.
# Usage: osd.sh volume up|down|mute | mic mute | brightness up|down | media play|next|prev

id_file="${XDG_RUNTIME_DIR:-/tmp}/osd-notify-id"

# notify <icon> <text> [percent]
# The level is drawn as a 25-char text bar (█ filled, ░ empty, 4% each) instead of mako's coloured progress bar
notify() {
    id=$(cat "$id_file" 2>/dev/null || echo 0)
    bar=
    if [ -n "$3" ]; then
        filled=$(( ($3 + 2) / 4 ))
        i=0
        while [ $i -lt 25 ]; do
            if [ $i -lt $filled ]; then bar="$bar█"; else bar="$bar░"; fi
            i=$((i + 1))
        done
    fi
    notify-send -p -r "$id" -t 1000 -u low -a osd -i "$1" "$2" "$bar" > "$id_file"
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

# brightness +|-  (5% steps)
brightness() {
    if [ -n "$(ls /sys/class/backlight 2>/dev/null)" ]; then
        b=$(brightnessctl -m set "5%$1" | cut -d, -f4 | tr -d %)
    else
        # No backlight (desktop): set the monitor itself over DDC/CI, VCP 0x10 = brightness.
        # Serialised with flock, since overlapping ddcutil calls on one bus fail.
        exec 9>"${XDG_RUNTIME_DIR:-/tmp}/osd-ddc.lock"
        flock 9
        bus_file="${XDG_RUNTIME_DIR:-/tmp}/osd-ddc-bus"   # cache: detect is slow
        [ -s "$bus_file" ] || ddcutil detect --brief | sed -n 's|.*/dev/i2c-||p' | head -1 > "$bus_file"
        bus=$(cat "$bus_file")
        cur=$(ddcutil --bus "$bus" -t getvcp 10 | awk '{ print $4 }')
        [ -n "$cur" ] || { rm -f "$bus_file"; exit 1; }
        b=$(( cur $1 5 ))
        [ "$b" -lt 0 ] && b=0
        [ "$b" -gt 100 ] && b=100
        ddcutil --bus "$bus" --noverify setvcp 10 "$b"
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
    "media play"|"media next"|"media prev")
        case "$2" in play) playerctl play-pause ;; next) playerctl next ;; prev) playerctl previous ;; esac
        sleep 0.2  # give the player time to update its metadata
        status=$(playerctl status 2>/dev/null) || exit 0
        track=$(playerctl metadata --format '{{artist}} – {{title}}' 2>/dev/null)
        icon=media-playback-start-symbolic
        [ "$status" = Paused ] && icon=media-playback-pause-symbolic
        notify "$icon" "${track:-$status}" ;;
esac
