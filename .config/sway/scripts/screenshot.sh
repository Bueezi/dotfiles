#!/bin/sh
# Region screenshot to the clipboard ($mod+Shift+s), or with `ocr` the text in it ($mod+Shift+x;
# tesseract: English, French, Dutch). wayfreeze covers the screen with a still image first,
# so video/animations stand still while you select; Esc in slurp cancels.

if [ "$1" = grab ]; then   # runs under wayfreeze; $2 = ocr for text
    # OCR: grab at 2x, tesseract reads small screen text much better that way. Otherwise grim's
    # default (the highest output scale), so the laptop's 1.35 stays sharp
    scale=; [ "$2" = ocr ] && scale="-s 2"
    img=$(mktemp --suffix=.png)
    g=$(slurp) && grim $scale -g "$g" "$img"; ok=$?
    pkill -x wayfreeze
    if [ $ok -ne 0 ]; then rm -f "$img"; exit 0; fi

    if [ "$2" = ocr ]; then
        text=$(tesseract "$img" - -l eng+fra+nld 2>/dev/null | tr -d '\f')
        if [ -n "$text" ]; then
            printf '%s' "$text" | wl-copy
            notify-send "Text in clipboard" "$(printf '%s' "$text" | head -3 | cut -c1-80)"
        else
            notify-send "No text found"
        fi
    else
        wl-copy < "$img" && notify-send "Screenshot in clipboard"
    fi
    rm -f "$img"
    exit 0
fi

exec wayfreeze --hide-cursor --after-freeze-cmd "$0 grab $1"
