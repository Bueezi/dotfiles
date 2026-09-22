#!/usr/bin/env bash

# Runs in a floating terminal so you can see output and type your sudo password.
update() {
    if [ "$(hostname)" = "void" ]; then
        sudo xbps-install -Su
    else
        echo "==> NixOS"
        sudo nixos-rebuild switch --upgrade
        if [ "$(readlink /run/booted-system/kernel)" != "$(readlink /run/current-system/kernel)" ]; then
            echo "    New kernel installed, reboot to use it."
        fi
    fi
    echo; echo "==> Flatpak"
    flatpak update -y
    echo; echo "==> Firmware"
    fwupdmgr refresh >/dev/null 2>&1
    fwupdmgr update
    echo; read -rp "Done. Press Enter to close."
}

if [ "$1" = "update" ]; then
    update
    exit
fi

choice=$(printf "󰋊  hibernate\n󰜉  reboot\n󰒲  sleep\n󰐥  power off\n󰚰  update" |
  fuzzel --dmenu --width 20 --lines 5)

[ "$choice" ] || exit 0
case "$choice" in
    *update) exec foot --app-id=floating "$0" update ;;
esac

if [ "$(hostname)" = "void" ]; then
    case "$choice" in
    *sleep)     loginctl suspend ;;
    *hibernate) loginctl hibernate ;;
    *reboot)    loginctl reboot ;;
    *"power off")  loginctl poweroff ;;
    esac
else
    case "$choice" in
    *sleep)     systemctl suspend ;;
    *hibernate) systemctl hibernate ;;
    *reboot)    systemctl reboot ;;
    *"power off")  systemctl poweroff ;;
    esac
fi
