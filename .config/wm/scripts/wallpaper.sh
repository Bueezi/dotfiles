#!/usr/bin/env bash
# Wallpaper on the tablet (i3, feh). Sway has HyprQuickPaper and a systemd timer instead
# (hyprquickpaper.nix); both use the same folder and the same "current wallpaper" link.
# Usage: wallpaper.sh restore     at login: the current one, and the slideshow if it was on
#        wallpaper.sh pick        rofi with thumbnails ($mod+Shift+w)
#        wallpaper.sh slideshow   on/off: a random one every 5 minutes ($mod+Shift+o); the
#                                 state is ~/.config/slideshow, like on sway
#        wallpaper.sh blur        on/off: a blurred copy of the wallpaper ($mod+Ctrl+w); the
#                                 state is ~/.config/wallpaper-blur

dir=~/Documents/sync/wp/active
cur=~/.local/state/wallpaper
pidf=${TMPDIR:-/tmp}/wallpaper-slideshow.pid
blur=~/.config/wallpaper-blur cache=~/.cache/wallpaper-blur

# Blur, faked: the see-through windows (xcompmgr only does transparency) show a blurred wallpaper
# behind them, which costs nothing per frame. picom's real blur re-blurs every frame on the CPU
# (2-5x the work, seconds per key press here). Only windows over other windows show them sharp.
# shown <wallpaper>: what feh shows, the wallpaper or (blur on) its blurred copy, made once and
# cached by path and date
shown() {
    [ -e "$blur" ] || { echo "$1"; return; }
    local out
    out=$cache/$(stat -L -c '%n %Y' "$(readlink -f "$1")" | md5sum | cut -c1-16).jpg
    if [ ! -e "$out" ]; then
        mkdir -p "$cache"
        # Shrunk, blurred, back to full size: a big blur in a fraction of the time
        magick "$1" -resize 10% -blur 0x3 -resize 1000% -quality 90 "jpg:$out.part" &&
            mv "$out.part" "$out" || { echo "$1"; return; }
    fi
    echo "$out"
}
# --no-fehbg: no ~/.fehbg in the home folder (the link below remembers the pick)
show() { feh --no-fehbg --bg-fill "$(shown "$1")"; }
set_wp() { mkdir -p "${cur%/*}"; ln -sfn "$1" "$cur"; show "$1"; }
images() { find -L "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort; }
random() { images | grep -vxF "$(readlink -f "$cur")" | shuf -n1; }

case "$1" in
restore)
    if [ -e "$cur" ]; then show "$cur"
    else f=$(random); [ -n "$f" ] && set_wp "$f"; fi
    # The slideshow waits its 5 minutes first: logging in keeps the wallpaper you had
    [ -e ~/.config/slideshow ] && setsid -f "$0" loop later >/dev/null 2>&1 ;;
pick)
    # Thumbnails: rofi shows each file as its own icon
    f=$(images | while read -r p; do printf '%s\0icon\x1f%s\n' "${p#"$dir"/}" "$p"; done |
        rofi -dmenu -i -show-icons -p wallpaper \
            -theme-str 'element-icon { size: 8em; } listview { columns: 3; lines: 3; }') || exit 0
    [ -n "$f" ] && set_wp "$dir/$f" ;;
slideshow)
    if [ -e ~/.config/slideshow ]; then
        rm -f ~/.config/slideshow
        pkill -f 'wallpaper\.sh loop( later)?$'; rm -f "$pidf"
        notify-send -a slideshow -i preferences-desktop-wallpaper-symbolic "Slideshow off"
    else
        touch ~/.config/slideshow
        setsid -f "$0" loop >/dev/null 2>&1
        notify-send -a slideshow -i preferences-desktop-wallpaper-symbolic "Slideshow on" "New wallpaper every 5 minutes"
    fi ;;
blur)
    if [ -e "$blur" ]; then rm -f "$blur"; state=off; else touch "$blur"; state=on; fi
    notify-send -a wallpaper -i preferences-desktop-wallpaper-symbolic "Blur $state"
    [ -e "$cur" ] && show "$cur" ;;
loop)   # the slideshow itself: a new one right away (`loop later`: after 5 minutes), then every 5
    # Only one: a loop from an earlier desktop session (`desktop` again) keeps running detached, and
    # several at once made the wallpaper change every few seconds
    for p in $(pgrep -f 'wallpaper\.sh loop( later)?$'); do [ "$p" != $$ ] && kill "$p"; done
    echo $$ > "$pidf"
    [ "$2" = later ] && sleep 300
    while :; do f=$(random); [ -n "$f" ] && set_wp "$f"; sleep 300; done ;;
esac
