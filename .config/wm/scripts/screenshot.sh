#!/bin/sh
# Region screenshot to the clipboard ($mod+Shift+s), or with `ocr` the text in it ($mod+Shift+x;
# tesseract: English, French, Dutch). Esc while selecting cancels.
# Sway: wayfreeze covers the screen with a still image first, so video/animations stand still
# while you select (slurp), then grim. i3 (X11, the tablet): scrot --select, frozen the same way.

# $1 = the screenshot, $2 = ocr for its text instead of the picture
finish() {
    if [ "$2" = ocr ]; then
        text=$(tesseract "$1" - -l eng+fra+nld 2>/dev/null | tr -d '\f')
        if [ -n "$text" ]; then
            if [ -n "$SWAYSOCK" ]; then printf '%s' "$text" | wl-copy
            else printf '%s' "$text" | xclip -selection clipboard; fi
            notify-send "Text in clipboard" "$(printf '%s' "$text" | head -3 | cut -c1-80)"
        else
            notify-send "No text found"
        fi
    elif [ -n "$SWAYSOCK" ]; then
        wl-copy < "$1" && notify-send "Screenshot in clipboard"
    else
        xclip -selection clipboard -t image/png -i "$1" && notify-send "Screenshot in clipboard"
    fi
    rm -f "$1"
}

if [ "$1" = grab ]; then   # sway: runs under wayfreeze; $2 = ocr for text
    # OCR: grab at 2x, tesseract reads small screen text much better that way. Otherwise grim's
    # default (the highest output scale), so the laptop's 1.35 stays sharp
    scale=; [ "$2" = ocr ] && scale="-s 2"
    img=$(mktemp --suffix=.png)
    g=$(slurp) && grim $scale -g "$g" "$img"; ok=$?
    pkill -x wayfreeze
    if [ $ok -ne 0 ]; then rm -f "$img"; exit 0; fi
    finish "$img" "$2"
    exit 0
fi

if [ -n "$SWAYSOCK" ]; then
    exec wayfreeze --hide-cursor --after-freeze-cmd "$0 grab $1"
fi

# i3: no 2x for OCR, the tablet's screen is dense enough. --overwrite: mktemp already made the file
img=$(mktemp --suffix=.png)
if ! scrot --select --freeze --overwrite "$img"; then rm -f "$img"; exit 0; fi
finish "$img" "$1"
