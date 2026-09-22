#!/usr/bin/env bash
# List sinks as "ID: description"
sink=$(pactl list sinks | awk '
  /^Sink #/ { id=substr($2,2) }
  /Description:/ { print id": "substr($0, index($0,$2)) }
' | fuzzel --dmenu)

[ -z "$sink" ] && exit

id="${sink%%:*}"
pactl set-default-sink "$id"
