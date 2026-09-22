#!/usr/bin/env bash

THEMES=(
    "Adwaita"
    "Adwaita-dark"
    # "Arc"
    # "Arc-Dark"
    # "Catppuccin-Mocha-Standard-Blue-Dark"
    # "Dracula"
)

selected=$(printf '%s\n' "${THEMES[@]}" | fuzzel --dmenu --prompt "GTK Theme: ")

[[ -z "$selected" ]] && exit 0

# Set color-scheme FIRST so Firefox/portal sees a consistent state
if [[ "${selected,,}" == *"dark"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
else
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
fi

# Then apply the actual GTK theme
gsettings set org.gnome.desktop.interface gtk-theme "$selected"

notify-send "Theme Switcher" "Applied theme: $selected" --icon=preferences-desktop-theme 2>/dev/null || true
