#!/bin/sh
# swayidle, started at login and restarted by `toggle.sh caffeine`.
# Screen off 10s after manual lock, lock at 3 min, screen off at 3m10s.
# The idle lock has a 5s grace period: it fades in, and touching the mouse or keyboard
# in those 5s dismisses it without the password. Manual and sleep locks don't.
exec swayidle -w \
    timeout 10  'pgrep swaylock && swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    timeout 180 'swaylock -f --grace 5' \
    timeout 190 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    before-sleep 'swaylock -f'
