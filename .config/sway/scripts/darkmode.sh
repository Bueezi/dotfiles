#!/bin/sh
# Light/dark toggle ($mod+Shift+t). color-scheme reaches libadwaita, LibreWolf and Electron
# through the portal; the Mono GTK3 themes and Papirus icons are in .configuration.nix, the Qt
# palettes in ~/.config/qt6ct/colors. Running foot windows get a signal; new ones are switched
# by fish (config.fish). The bar, fuzzel, mako and swaylock stay black.
# Usage: darkmode.sh          toggle
#        darkmode.sh apply    only write qt6ct's file for the current mode
#                             (sway runs this at login; dconf's color-scheme is the source of truth)
key=/org/gnome/desktop/interface

current=dark
[ "$(dconf read $key/color-scheme)" = "'prefer-light'" ] && current=light
if [ "$1" = apply ]; then mode=$current
elif [ $current = dark ]; then mode=light
else mode=dark
fi

if [ $mode = dark ]; then
    theme=Mono-dark icons=Papirus-Dark palette=mono-dark sig=USR1 icon=weather-clear-night-symbolic
else
    theme=Mono icons=Papirus palette=mono sig=USR2 icon=weather-clear-symbolic
fi

# qt6ct: replaced with mv, since running Qt apps only reload when a file in its folder is replaced
q=~/.config/qt6ct
cat > $q/qt6ct.conf.new <<EOF
[Appearance]
style=Fusion
custom_palette=true
color_scheme_path=$q/colors/$palette.conf
icon_theme=$icons
standard_dialogs=xdgdesktopportal
EOF
mv $q/qt6ct.conf.new $q/qt6ct.conf
[ "$1" = apply ] && exit 0

dconf write $key/color-scheme "'prefer-$mode'"
dconf write $key/gtk-theme "'$theme'"
dconf write $key/icon-theme "'$icons'"
pkill -$sig -x foot

notify-send -t 1500 -a darkmode -i $icon "$mode mode"
