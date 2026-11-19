#!/bin/sh
# darkmode.sh: toggle light/dark. `apply`: only set GTK3, icons, qt6ct and foot for the current mode
key=/org/gnome/desktop/interface

current=dark
[ "$(dconf read $key/color-scheme)" = "'prefer-light'" ] && current=light
# Noctalia's color-scheme write may not have landed yet
[ -n "$NOCTALIA_THEME_MODE" ] && current=$NOCTALIA_THEME_MODE
if [ "$1" = apply ]; then mode=$current
elif [ $current = dark ]; then mode=light
else mode=dark
fi

if [ $mode = dark ]; then
    theme=Mono-dark icons=Papirus-Dark palette=mono-dark sig=USR1 icon=weather-clear-night-symbolic
else
    theme=adw-gtk3 icons=Papirus palette=mono sig=USR2 icon=weather-clear-symbolic
fi

# mv: running Qt apps only reload when a file is replaced
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
dconf write $key/gtk-theme "'$theme'"
dconf write $key/icon-theme "'$icons'"

pkill -$sig -x foot
[ "$1" = apply ] && exit 0

dconf write $key/color-scheme "'prefer-$mode'"

notify-send -t 1500 -a darkmode -i $icon "$mode mode"
