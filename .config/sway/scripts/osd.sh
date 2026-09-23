#!/bin/sh
# Media/brightness keys with a short-lived notification that replaces itself.
# Usage: osd.sh volume up|down|mute | mic mute | brightness up|down | media play|next|prev

id_file="${XDG_RUNTIME_DIR:-/tmp}/osd-notify-id"

# notify <icon> <text> [percent]
notify() {
    id=$(cat "$id_file" 2>/dev/null || echo 0)
    notify-send -p -r "$id" -t 1000 -u low -a osd -i "$1" \
        ${3:+-h int:value:$3} "$2" > "$id_file"
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

case "$1 $2" in
    "volume up")       wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+; volume ;;
    "volume down")     wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-;        volume ;;
    "volume mute")     wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle;       volume ;;
    "mic mute")
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
            notify microphone-sensitivity-muted-symbolic "Mic muted"
        else
            notify audio-input-microphone-symbolic "Mic on"
        fi ;;
    "brightness up")   b=$(brightnessctl -m set 5%+ | cut -d, -f4 | tr -d %)
                       notify display-brightness-symbolic "Brightness $b%" "$b" ;;
    "brightness down") b=$(brightnessctl -m set 5%- | cut -d, -f4 | tr -d %)
                       notify display-brightness-symbolic "Brightness $b%" "$b" ;;
    "media play"|"media next"|"media prev")
        case "$2" in play) playerctl play-pause ;; next) playerctl next ;; prev) playerctl previous ;; esac
        sleep 0.2  # give the player time to update its metadata
        status=$(playerctl status 2>/dev/null) || exit 0
        track=$(playerctl metadata --format '{{artist}} – {{title}}' 2>/dev/null)
        icon=media-playback-start-symbolic
        [ "$status" = Paused ] && icon=media-playback-pause-symbolic
        notify "$icon" "${track:-$status}" ;;
esac
