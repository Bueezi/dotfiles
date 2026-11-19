#!/bin/sh
# Noctalia's idle sleep: the desktop waits 10 more minutes, then sleep once no audio plays
pidfile="$XDG_RUNTIME_DIR/idle-nap.pid"
[ "$1" = nap ] || { echo "usage: $0 nap noctalia" >&2; exit 1; }
echo $$ >"$pidfile"
if [ "$2" = noctalia ] && [ ! -d /sys/class/power_supply/BAT0 ]; then sleep 600; fi
while pw-dump | jq -e 'any(.[]; .info.props["media.class"]? == "Audio/Sink" and .info.state? == "running")' >/dev/null; do
    sleep 10
done
rm -f "$pidfile"
exec systemctl sleep
