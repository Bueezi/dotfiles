#!/usr/bin/env bash
# Power menu (Mod+Shift+P). Update/rebuild/sync run in a scratchpad terminal that hides after sudo
term=(foot --app-id=scratch-power)
win() { umbriel windows --json | jq -r 'map(select(.app_id == "scratch-power")) | first | .id // empty'; }
hide() { umbriel msg window-focus "$(win)" && umbriel msg window-move-to-scratchpad; } >/dev/null
show() { umbriel msg window-focus "$(win)" >/dev/null; }

auth() {
    if ! sudo -v; then
        notify-send -u critical -a power -i dialog-error-symbolic "Authentication failed"
        read -rp "Press Enter to close."
        exit 1
    fi
    hide
    notify-send -a power -i system-run-symbolic "$1" "Started, running in the background"
}

sync_first() {
    echo "==> Sync (cu)"
    cu || { failed+=" Sync"; echo "    Sync failed, using the local config"; }
    echo
    # sudo's cached password may have run out during a long cu
    sudo -n true 2>/dev/null || { show; sudo -v; hide; }
}

report() {
    show
    if [ -n "$failed" ]; then
        notify-send -u critical -a "${1,,}" -i dialog-error-symbolic "$1" "Failed:$failed"
        echo; read -rp "Failed:$failed (see above). Press Enter to close."
    else
        notify-send -a "${1,,}" -i emblem-ok-symbolic "$1" "$2"
    fi
}

update() {
    failed=
    auth Update
    sync_first
    echo "==> NixOS"
    rb -u || failed+=" NixOS"
    if [ "$(readlink /run/booted-system/kernel)" != "$(readlink /run/current-system/kernel)" ]; then
        echo "    New kernel installed, reboot to use it."
    fi
    echo; echo "==> Flatpak"
    flatpak update -y || failed+=" Flatpak"
    echo; echo "==> Firmware"
    fwupdmgr refresh >/dev/null 2>&1
    if fwupdmgr get-updates >/dev/null 2>&1; then
        show   # fwupdmgr asks before flashing
        fwupdmgr update
    else
        echo "No firmware updates."
    fi
    report Update Finished
    [ -n "$failed" ] || { echo; read -rp "Done. Press Enter to close."; }
}

rebuild() {
    failed=
    auth Rebuild
    sync_first
    echo "==> rb"
    rb || failed+=" Rebuild"
    if [ -n "$failed" ]; then
        report Rebuild
    else
        notify-send -a rebuild -i emblem-ok-symbolic "Rebuild" "Synced and rebuilt"
        sleep 1
    fi
}

sync() {
    echo "==> Dotfiles sync (cu)"
    if cu; then
        notify-send -a sync -i emblem-ok-symbolic "Sync" "Dotfiles synced"
        echo; read -rp "Done. Press Enter to close."
    else
        notify-send -u critical -a sync -i dialog-error-symbolic "Sync" "Dotfiles sync failed"
        echo; read -rp "Failed. Press Enter to close."
    fi
}

case "$1" in sync|update|rebuild) "$1"; exit ;; esac

# Only the laptop has a swap partition to resume from
hibernate=; [ -d /sys/class/power_supply/BAT0 ] && hibernate="󰋊  hibernate\n"
choice=$(printf "${hibernate}󰜉  reboot\n󰒲  sleep\n󰐥  power off\n󰚰  update\n󱄅  rebuild\n󰓦  sync" |
  noctalia dmenu -p power)

[ "$choice" ] || exit 0
case "$choice" in
    *update)  exec "${term[@]}" "$0" update ;;
    *rebuild) exec "${term[@]}" "$0" rebuild ;;
    *sync)    exec "${term[@]}" "$0" sync ;;
esac

case "$choice" in
    *sleep)       systemctl sleep ;;
    *hibernate)   systemctl hibernate ;;
    *reboot)      systemctl reboot ;;
    *"power off") systemctl poweroff ;;
esac
