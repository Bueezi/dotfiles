#!/bin/sh
# Region screenshot to the clipboard, Save in the notification writes it to $dir
# `ocr`: the text in it; `notify`: Noctalia's pipe_command (PNG on stdin, already copied)
dir=$HOME/Downloads

offer() {
    name=screenshot_$(date +%Y%m%d_%H%M%S).png
    (
        a=$(notify-send -t 10000 -i "$1" --action=save=Save --wait "Screenshot in clipboard")
        [ "$a" = save ] && mkdir -p "$dir" && cp "$1" "$dir/$name"
        rm -f "$1"
    ) </dev/null >/dev/null 2>&1 &
}

finish() {
    if [ "$2" = ocr ]; then
        text=$(tesseract "$1" - -l eng+fra+nld 2>/dev/null | tr -d '\f')
        if [ -n "$text" ]; then
            printf '%s' "$text" | wl-copy
            notify-send "Text in clipboard" "$(printf '%s' "$text" | head -3 | cut -c1-80)"
        else
            notify-send "No text found"
        fi
        rm -f "$1"
    else
        wl-copy < "$1" && offer "$1"
    fi
}

if [ "$1" = notify ]; then
    img=$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}" --suffix=.png)
    cat > "$img"
    offer "$img"
    exit 0
fi

if [ "$1" = grab ]; then   # under wayfreeze
    # 2x: tesseract reads small text much better
    scale=; [ "$2" = ocr ] && scale="-s 2"
    img=$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}" --suffix=.png)
    g=$(slurp) && grim $scale -g "$g" "$img"; ok=$?
    pkill -x wayfreeze
    if [ $ok -ne 0 ]; then rm -f "$img"; exit 0; fi
    finish "$img" "$2"
    exit 0
fi

exec wayfreeze --hide-cursor --after-freeze-cmd "$0 grab $1"
