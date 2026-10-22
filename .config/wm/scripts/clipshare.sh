#!/bin/sh
# The tablet: Termux:X11's clipboard sharing (the desktop's clipboard with Android's) on or off, with
# a notification. `desktop` turns it off at each start. termux-x11-preference takes key:value, its
# `list` prints "key"="value" lines, and it waits for Termux:X11's activity (hence the timeout)
now=$(timeout 10 termux-x11-preference list 2>/dev/null | grep '^"clipboardEnable"=' | cut -d'"' -f4)
case "$now" in
true)  new=false msg="Clipboard sharing off|Android's clipboard stays apart" ;;
false) new=true msg="Clipboard sharing on|Copies go to and from Android" ;;
*)     notify-send -t 3000 -a clipboard "Clipboard sharing" "Termux:X11 didn't answer"; exit 1 ;;
esac
timeout 10 termux-x11-preference clipboardEnable:$new >/dev/null 2>&1 &&
    notify-send -t 1500 -a clipboard -i edit-paste-symbolic "${msg%|*}" "${msg#*|}"
