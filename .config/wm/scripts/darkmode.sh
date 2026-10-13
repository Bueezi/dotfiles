#!/bin/sh
# Light/dark toggle ($mod+Shift+t). color-scheme reaches libadwaita, LibreWolf and Electron
# through the portal; GTK3 switches between Mono-dark (~/.local/share/themes) and adw-gtk3, the Qt
# palettes are in ~/.config/qt6ct/colors. Sway: running foot windows get a signal; new ones are
# switched by fish (config.fish). i3 (X11, the tablet): GTK reads XSETTINGS there, not dconf, so
# xsettingsd gets the theme names; alacritty reloads the colours file it imports by itself.
# The bar, launcher, notifications and lock screen stay black.
# Usage: darkmode.sh          toggle
#        darkmode.sh apply    only write qt6ct's file and the themes for the current mode
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
    theme=adw-gtk3 icons=Papirus palette=mono sig=USR2 icon=weather-clear-symbolic
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
# Themes for the mode, also on apply (fixes a saved theme name that no longer exists)
dconf write $key/gtk-theme "'$theme'"
dconf write $key/icon-theme "'$icons'"

# i3: xsettingsd and alacritty's colours (both untracked, written here like qt6ct.conf)
if [ -z "$SWAYSOCK" ]; then
    mkdir -p ~/.config/xsettingsd ~/.config/alacritty
    printf 'Net/ThemeName "%s"\nNet/IconThemeName "%s"\n' "$theme" "$icons" > ~/.config/xsettingsd/xsettingsd.conf
    # Reload it, or start it (at login, `darkmode.sh apply` runs before anything else needs it)
    pkill -HUP -x xsettingsd || setsid -f xsettingsd >/dev/null 2>&1
    if [ $mode = dark ]; then bg=000000 fg=ffffff; else bg=ffffff fg=000000; fi
    printf '[colors.primary]\nbackground = "#%s"\nforeground = "#%s"\n' $bg $fg > ~/.config/alacritty/colors.toml.new
    mv ~/.config/alacritty/colors.toml.new ~/.config/alacritty/colors.toml
fi
[ "$1" = apply ] && exit 0

dconf write $key/color-scheme "'prefer-$mode'"
[ -n "$SWAYSOCK" ] && pkill -$sig -x foot

notify-send -t 1500 -a darkmode -i $icon "$mode mode"
