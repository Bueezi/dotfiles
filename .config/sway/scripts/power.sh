#!/usr/bin/env bash

choice=$(printf "  sleep\n  hibernate\n  reboot\n  poweroff" |
  fuzzel --dmenu --width 20 --lines 4)

if [ "$(hostname)" = "void" ]; then
    case "$choice" in
    *sleep)     loginctl suspend ;;
    *hibernate) loginctl hibernate ;;
    *reboot)    loginctl reboot ;;
    *poweroff)  loginctl poweroff ;;
    esac
else
    case "$choice" in
    *sleep)     systemctl suspend ;;
    *hibernate) systemctl hibernate ;;
    *reboot)    systemctl reboot ;;
    *poweroff)  systemctl poweroff ;;
    esac
fi
