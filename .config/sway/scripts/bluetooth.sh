#!/usr/bin/env bash
# Bluetooth menu in fuzzel. Powers the radio on first (it's off at boot on the laptop),
# then hands off to bzmenu, or falls back to a small bluetoothctl menu.

rfkill unblock bluetooth 2>/dev/null
if ! bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power on >/dev/null || { notify-send "Bluetooth" "Could not power on the adapter"; exit 1; }
    sleep 1   # give the adapter a moment before listing devices
fi

command -v bzmenu >/dev/null && exec bzmenu --launcher fuzzel

menu() { fuzzel --dmenu --prompt "bluetooth ❯ " --width 40 "$@"; }

# Lines look like "󰂱  Name  [AA:BB:CC:DD:EE:FF]"; connected devices get a different icon.
devices() {
    bluetoothctl devices | while read -r _ mac name; do
        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            printf '󰂱  %s  [%s]\n' "$name" "$mac"
        else
            printf '󰂯  %s  [%s]\n' "$name" "$mac"
        fi
    done
}

choice=$({ devices; printf '󰂰  scan for devices\n󰂲  power off\n'; } | menu) || exit 0

case "$choice" in
    *"scan for devices")
        notify-send -t 8000 "Bluetooth" "Scanning for 8 seconds…"
        bluetoothctl --timeout 8 scan on >/dev/null
        exec "$0" ;;
    *"power off")
        bluetoothctl power off >/dev/null
        notify-send "Bluetooth" "Powered off"
        exit 0 ;;
esac

mac=${choice##*[}; mac=${mac%]}
name=${choice#*  }; name=${name%  \[*}

if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
    bluetoothctl disconnect "$mac" >/dev/null && notify-send "Bluetooth" "Disconnected $name"
    exit 0
fi

if ! bluetoothctl info "$mac" | grep -q "Paired: yes"; then
    bluetoothctl --timeout 15 pair "$mac" >/dev/null
    bluetoothctl trust "$mac" >/dev/null
fi
if bluetoothctl --timeout 10 connect "$mac" | grep -q "Connection successful"; then
    notify-send "Bluetooth" "Connected $name"
else
    notify-send "Bluetooth" "Failed to connect $name"
fi
