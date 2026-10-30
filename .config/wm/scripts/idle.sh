#!/bin/sh
# swayidle, started at login and restarted by `toggle.sh caffeine`.
# Lock at 3 min, screen off at 3m10s, sleep at 5 min (laptop) / 15 min (desktop).
# After a manual lock the screen goes off sooner: 20s (laptop) / 2 min (desktop).
# The idle lock has a 5s grace period: it fades in, and touching the mouse or keyboard
# in those 5s dismisses it without the password. Manual and sleep locks don't.
# Playing audio holds off the sleep (not the lock or screen off): `idle.sh nap` waits
# until no speaker is in use, and the resume cancels it through its PID file.
pidfile="$XDG_RUNTIME_DIR/idle-nap.pid"
if [ "$1" = nap ]; then
    echo $$ >"$pidfile"
    while pw-dump | jq -e 'any(.[]; .info.props["media.class"]? == "Audio/Sink" and .info.state? == "running")' >/dev/null; do
        sleep 10
    done
    rm -f "$pidfile"
    exec systemctl sleep
fi

if [ -d /sys/class/power_supply/BAT0 ]; then
    lockoff=20 nap=300
else
    lockoff=120 nap=900
fi
exec swayidle -w \
    timeout $lockoff 'pgrep swaylock && swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    timeout 180 'swaylock -f --grace 5' \
    timeout 190 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    timeout $nap "$0 nap" resume "test -f $pidfile && kill \$(cat $pidfile); rm -f $pidfile" \
    before-sleep 'swaylock -f'
