#!/usr/bin/env bash

# Runs in a scratchpad terminal (hide/show with $mod+minus) so you can see output and type your sudo password.
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
    echo; echo "==> Nix profile"
    nix profile upgrade --all --refresh
    echo; echo "==> Flatpak"
    flatpak update -y
    echo; echo "==> Firmware"
    fwupdmgr refresh >/dev/null 2>&1
    fwupdmgr update
    echo; read -rp "Done. Press Enter to close."
}

# Rebuild the NixOS config (no channel upgrade) and report the result as a notification.
rebuild() {
    echo "==> nixos-rebuild switch"
    if sudo nixos-rebuild switch; then
        notify-send -a rebuild -i emblem-ok-symbolic "Rebuild" "nixos-rebuild switch succeeded"
        sleep 1
    else
        notify-send -u critical -a rebuild -i dialog-error-symbolic "Rebuild" "nixos-rebuild switch failed"
        echo; read -rp "Failed. Press Enter to close."
    fi
}

if [ "$1" = "update" ]; then
    update
    exit
fi
if [ "$1" = "rebuild" ]; then
    rebuild
    exit
fi

choice=$(printf "󰋊  hibernate\n󰜉  reboot\n󰒲  sleep\n󰐥  power off\n󰚰  update\n󱄅  rebuild" |
  fuzzel --dmenu --width 20 --lines 6)

[ "$choice" ] || exit 0
case "$choice" in
    *update)  exec foot --app-id=scratch-power "$0" update ;;
    *rebuild) exec foot --app-id=scratch-power "$0" rebuild ;;
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
