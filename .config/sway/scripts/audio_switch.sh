#!/usr/bin/env bash
# List sinks as "ID: description"
sink=$(pw-dump | jq -r '.[]
  | select(.type == "PipeWire:Interface:Node" and .info.props."media.class" == "Audio/Sink")
  | "\(.id): \(.info.props."node.description")"' | fuzzel --dmenu)

[ -z "$sink" ] && exit

id="${sink%%:*}"
wpctl set-default "$id"
