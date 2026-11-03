#!/usr/bin/env bash
# Power menu (Mod+Shift+P). NixOS: sleep, hibernate (laptop), reboot, power off, update, rebuild,
# sync. The tablet (Termux, i3): hide, close desktop, exit Termux, update, rebuild, sync; Android does
# the rest. Update and rebuild sync first (cu), so they build the newest config from all machines.
# Update, rebuild and sync run in a scratchpad terminal (show/hide: Umbriel Mod+Space, i3 $mod+minus)
# so you can see output and type your sudo password. Once the password is in (sudo caches it), the
# terminal hides itself and comes back only when it needs you: a failure, a firmware prompt, or the
# end of an update.

# Umbriel: foot, Noctalia's picker, the window id from app_id. i3: alacritty, rofi, i3-msg, by class
if [ -n "$UMBRIEL_SOCKET" ]; then
    term=(foot --app-id=scratch-power)
    win() { umbriel windows --json | jq -r 'map(select(.app_id == "scratch-power")) | first | .id // empty'; }
    hide() { umbriel msg window-focus "$(win)" && umbriel msg window-move-to-scratchpad; } >/dev/null
    show() { umbriel msg window-focus "$(win)" >/dev/null; }
else
    term=(alacritty --class scratch-power -e)
    hide() { i3-msg -q '[class="^scratch-power$"] move scratchpad'; }
    show() { i3-msg -q '[class="^scratch-power$"] focus'; }
fi

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

# cu before rb: the other machines' config changes in, this one's out. A failed sync (offline, a
# conflict) doesn't stop what follows, which then uses the local copy; it's named at the end
sync_first() {
    echo "==> Sync (cu)"
    cu || { failed+=" Sync"; echo "    Sync failed, using the local config"; }
    echo
    # cu took long (the first clone of ~/Documents/sync): sudo's cached password may have run out
    [ -n "$TERMUX_VERSION" ] || sudo -n true 2>/dev/null || { show; sudo -v; hide; }
}

# The end of update/rebuild: a notification, and the terminal back when something failed ($2 = the
# message when all went well)
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
    # Each part runs even if one before it failed; the failed ones are named at the end
    failed=
    # Tablet: rb -u (termux.sh) updates everything, pkg included
    if [ -n "$TERMUX_VERSION" ]; then
        sync_first
        echo "==> Termux"
        rb -u || failed+=" Termux"
        report Update Finished
        [ -n "$failed" ] || { echo; read -rp "Done. Press Enter to close."; }
        return
    fi
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

# Apply the config with rb, nothing upgraded (NixOS: nixos-rebuild switch; the tablet: termux.sh).
# Stays hidden when all went well
rebuild() {
    failed=
    [ -n "$TERMUX_VERSION" ] || auth Rebuild
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

# Sync with `cu` (~/.local/bin/cu): dotfiles (commit tracked changes, pull, push), then ~/Documents/sync.
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

if [ -n "$TERMUX_VERSION" ]; then
    choice=$(printf "󰓎  hide desktop\n󰍃  close desktop\n󰐥  exit termux\n󰚰  update\n󱄅  rebuild\n󰓦  sync" |
      rofi -dmenu -i -p power)
else
    # Hibernate only on the laptop: the desktop has no swap partition to resume from (zram only)
    hibernate=; [ -d /sys/class/power_supply/BAT0 ] && hibernate="󰋊  hibernate\n"
    choice=$(printf "${hibernate}󰜉  reboot\n󰒲  sleep\n󰐥  power off\n󰚰  update\n󱄅  rebuild\n󰓦  sync" |
      noctalia dmenu -p power)
fi

[ "$choice" ] || exit 0
case "$choice" in
    *update)  exec "${term[@]}" "$0" update ;;
    *rebuild) exec "${term[@]}" "$0" rebuild ;;
    *sync)    exec "${term[@]}" "$0" sync ;;
    # hide: back to Android, all keeps running. stop: the X server goes, i3 with it; Termux keeps
    # running. exit: Termux too
    *"hide desktop")  exec "$HOME/.config/termux/bin/desktop" hide ;;
    *"close desktop") exec "$HOME/.config/termux/bin/desktop" stop ;;
    *"exit termux")   exec "$HOME/.config/termux/bin/desktop" exit ;;
esac

case "$choice" in
    *sleep)       systemctl sleep ;;   # like the lid and idle: suspend-then-hibernate on the laptop
    *hibernate)   systemctl hibernate ;;
    *reboot)      systemctl reboot ;;
    *"power off") systemctl poweroff ;;
esac
