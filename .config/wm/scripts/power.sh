#!/usr/bin/env bash
# Power menu ($mod+Shift+p). NixOS: sleep, hibernate (laptop), reboot, power off, update, rebuild,
# sync. The tablet (Termux, i3): update, sync, leave desktop; Android does the rest.
# Update, rebuild and sync run in a scratchpad terminal (hide/show with $mod+minus) so you can see
# output and type your sudo password. Once the password is in (sudo caches it), the terminal hides
# itself and comes back only when it needs you: a failure, a firmware prompt, or the end of an update.

# Sway: foot, fuzzel, swaymsg, the window found by app_id. i3: alacritty, rofi, i3-msg, by class
if [ -n "$SWAYSOCK" ]; then
    msg=swaymsg crit='app_id="^scratch-power$"' term=(foot --app-id=scratch-power)
else
    msg=i3-msg crit='class="^scratch-power$"' term=(alacritty --class scratch-power -e)
fi
hide() { $msg -q "[$crit] move scratchpad"; }
show() { $msg -q "[$crit] focus"; }

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
    # Tablet: Termux's packages, then its setup script applies the package list (like a rebuild)
    if [ -n "$TERMUX_VERSION" ]; then
        echo "==> Termux"
        if pkg upgrade -y && bash ~/.config/scripts/termux.sh; then
            notify-send -a update -i emblem-ok-symbolic "Update" "Finished"
        else
            notify-send -u critical -a update -i dialog-error-symbolic "Update" "Failed"
        fi
        show
        echo; read -rp "Done. Press Enter to close."
        return
    fi
    auth Update
    echo "==> NixOS"
    sudo nixos-rebuild switch --upgrade
    if [ "$(readlink /run/booted-system/kernel)" != "$(readlink /run/current-system/kernel)" ]; then
        echo "    New kernel installed, reboot to use it."
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

# Sync with `cu` (~/.local/bin/cu): dotfiles (commit tracked changes, pull, push), then ~/Documents/sync.
# Full path: the sway session's PATH doesn't include ~/.local/bin (only shells add it)
sync() {
    echo "==> Dotfiles sync (cu)"
    if "$HOME/.local/bin/cu"; then
        notify-send -a sync -i emblem-ok-symbolic "Sync" "Dotfiles synced"
        echo; read -rp "Done. Press Enter to close."
    else
        notify-send -u critical -a sync -i dialog-error-symbolic "Sync" "Dotfiles sync failed"
        echo; read -rp "Failed. Press Enter to close."
    fi
}

# Wallpaper slideshow on/off ($mod+Shift+o runs `power.sh slideshow`; timer from hyprquickpaper.nix).
# The state is kept in ~/.config/slideshow, so sway starts it again at login.
slideshow() {
    if systemctl --user is-active -q wallpaper-slideshow.timer; then
        systemctl --user stop wallpaper-slideshow.timer
        rm -f ~/.config/slideshow
        notify-send -a slideshow -i preferences-desktop-wallpaper-symbolic "Slideshow off"
    else
        systemctl --user start wallpaper-slideshow.timer
        # New wallpaper right away (the timer counts its 5 minutes from this run)
        systemctl --user start --no-block wallpaper-slideshow.service
        touch ~/.config/slideshow
        notify-send -a slideshow -i preferences-desktop-wallpaper-symbolic "Slideshow on" "New wallpaper every 5 minutes"
    fi
}

case "$1" in slideshow|sync|update|rebuild) "$1"; exit ;; esac

if [ -n "$TERMUX_VERSION" ]; then
    choice=$(printf "󰚰  update\n󰓦  sync\n󰍃  leave desktop" | rofi -dmenu -i -p power)
else
    # Hibernate only on the laptop: the desktop has no swap partition to resume from (zram only)
    hibernate=; [ -d /sys/class/power_supply/BAT0 ] && hibernate="󰋊  hibernate\n"
    choice=$(printf "${hibernate}󰜉  reboot\n󰒲  sleep\n󰐥  power off\n󰚰  update\n󱄅  rebuild\n󰓦  sync" |
      fuzzel --dmenu --width 20 --lines 7)
fi

[ "$choice" ] || exit 0
case "$choice" in
    *update)  exec "${term[@]}" "$0" update ;;
    *rebuild) exec "${term[@]}" "$0" rebuild ;;
    *sync)    exec "${term[@]}" "$0" sync ;;
    # Stopping Termux:X11's server ends i3 with it; Termux itself keeps running
    *"leave desktop") exec pkill -f termux.x11 ;;
esac

case "$choice" in
    *sleep)       systemctl suspend ;;
    *hibernate)   systemctl hibernate ;;
    *reboot)      systemctl reboot ;;
    *"power off") systemctl poweroff ;;
esac
