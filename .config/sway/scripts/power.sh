#!/usr/bin/env bash

# Runs in a scratchpad terminal (hide/show with $mod+minus) so you can see output and type your sudo password.
# Once the password is in (sudo caches it), the terminal hides itself and comes back only when
# it needs you: a failure, a firmware prompt, or the end of an update.
hide() { swaymsg -q '[app_id="^scratch-power$"] move scratchpad'; }
show() { swaymsg -q '[app_id="^scratch-power$"] focus'; }

# Ask for the sudo password up front, then hide and say it started. $1 = name for the notification
auth() {
    if ! sudo -v; then
        notify-send -u critical -a power -i dialog-error-symbolic "Authentication failed"
        read -rp "Press Enter to close."
        exit 1
    fi
    hide
    notify-send -a power -i system-run-symbolic "$1" "Started, running in the background"
}

update() {
    auth Update
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
    if fwupdmgr get-updates >/dev/null 2>&1; then
        show   # fwupdmgr asks before flashing
        fwupdmgr update
    else
        echo "No firmware updates."
    fi
    notify-send -a update -i emblem-ok-symbolic "Update" "Finished"
    show
    echo; read -rp "Done. Press Enter to close."
}

# Rebuild the NixOS config (no channel upgrade) and report the result as a notification.
rebuild() {
    auth Rebuild
    echo "==> nixos-rebuild switch"
    if sudo nixos-rebuild switch; then
        notify-send -a rebuild -i emblem-ok-symbolic "Rebuild" "nixos-rebuild switch succeeded"
        sleep 1
    else
        notify-send -u critical -a rebuild -i dialog-error-symbolic "Rebuild" "nixos-rebuild switch failed"
        show
        echo; read -rp "Failed. Press Enter to close."
    fi
}

# Sync dotfiles with `cu` from ~/.bashrc (commit tracked changes, pull, push).
sync() {
    echo "==> Dotfiles sync (cu)"
    if bash -ic cu; then
        notify-send -a sync -i emblem-ok-symbolic "Sync" "Dotfiles synced"
        echo; read -rp "Done. Press Enter to close."
    else
        notify-send -u critical -a sync -i dialog-error-symbolic "Sync" "Dotfiles sync failed"
        echo; read -rp "Failed. Press Enter to close."
    fi
}

if [ "$1" = "sync" ]; then
    sync
    exit
fi
if [ "$1" = "update" ]; then
    update
    exit
fi
if [ "$1" = "rebuild" ]; then
    rebuild
    exit
fi

choice=$(printf "󰋊  hibernate\n󰜉  reboot\n󰒲  sleep\n󰐥  power off\n󰚰  update\n󱄅  rebuild\n󰓦  sync" |
  fuzzel --dmenu --width 20 --lines 7)

[ "$choice" ] || exit 0
case "$choice" in
    *update)  exec foot --app-id=scratch-power "$0" update ;;
    *rebuild) exec foot --app-id=scratch-power "$0" rebuild ;;
    *sync)    exec foot --app-id=scratch-power "$0" sync ;;
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
