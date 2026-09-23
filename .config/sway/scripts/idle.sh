#!/bin/sh
# swayidle, started at login and restarted by caffeine.sh.
# Screen off 10s after manual lock, lock at 3 min, screen off at 3m10s.
exec swayidle -w \
    timeout 10  'pgrep swaylock && swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    timeout 180 'swaylock -f' \
    timeout 190 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    before-sleep 'swaylock -f'
