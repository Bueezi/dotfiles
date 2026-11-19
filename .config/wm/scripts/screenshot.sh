#!/bin/sh
# Region screenshot to the clipboard; `ocr`: the text in it
finish() {
    if [ "$2" = ocr ]; then
        text=$(tesseract "$1" - -l eng+fra+nld 2>/dev/null | tr -d '\f')
        if [ -n "$text" ]; then
            printf '%s' "$text" | wl-copy
            notify-send "Text in clipboard" "$(printf '%s' "$text" | head -3 | cut -c1-80)"
        else
            notify-send "No text found"
        fi
    else
        wl-copy < "$1" && notify-send "Screenshot in clipboard"
    fi
    rm -f "$1"
}

if [ "$1" = grab ]; then   # under wayfreeze
    # 2x: tesseract reads small text much better
    scale=; [ "$2" = ocr ] && scale="-s 2"
    img=$(mktemp --suffix=.png)
    g=$(slurp) && grim $scale -g "$g" "$img"; ok=$?
    pkill -x wayfreeze
    if [ $ok -ne 0 ]; then rm -f "$img"; exit 0; fi
    finish "$img" "$2"
    exit 0
fi

exec wayfreeze --hide-cursor --after-freeze-cmd "$0 grab $1"
