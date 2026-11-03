#!/bin/sh
# `idle.sh nap noctalia`: Noctalia's idle sleep (~/.config/noctalia/config.toml), at 5 min on both
# machines (its config is shared), so the desktop waits 10 more. Playing audio holds off the sleep
# (not the lock or screen off): it waits until no speaker is in use, and Noctalia's resume_command
# cancels it through its PID file.
pidfile="$XDG_RUNTIME_DIR/idle-nap.pid"
[ "$1" = nap ] || { echo "usage: $0 nap noctalia" >&2; exit 1; }
echo $$ >"$pidfile"
if [ "$2" = noctalia ] && [ ! -d /sys/class/power_supply/BAT0 ]; then sleep 600; fi
while pw-dump | jq -e 'any(.[]; .info.props["media.class"]? == "Audio/Sink" and .info.state? == "running")' >/dev/null; do
    sleep 10
done
rm -f "$pidfile"
exec systemctl sleep
