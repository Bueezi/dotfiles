#!/usr/bin/env bash
# Clipboard history, Windows style: a floating terminal with the list on the left and a full
# preview (multi-line text, or the picture itself) on the right. Enter pastes into the window
# that had focus (Ctrl+V, or Ctrl+Shift+V in terminals). History: cliphist, filled by clipstore.sh.
# Sway: foot (pictures as sixel), wl-copy, wtype. i3 (X11, the tablet): alacritty (no sixel:
# chafa's block characters), xclip, xdotool. Both: cliphist, fzf, chafa, jq

self=$(realpath "$0")

case "$1" in
pick)   # runs inside the foot window; writes the chosen line to $2
    cliphist list | fzf --delimiter='\t' --with-nth=2.. --no-sort --layout=reverse \
        --prompt 'clip ❯ ' --info=inline-right --no-separator --no-scrollbar \
        --header '↵ paste · ^D delete' --header-first --color='header:dim' \
        --preview "$self preview {1} {2..}" --preview-window 'right,55%,wrap,border-left' \
        --bind "ctrl-d:execute-silent(printf '%s\t\n' {1} | cliphist delete)+reload(cliphist list)" \
        > "$2"
    exit ;;
preview)
    if [[ $3 == "[[ binary data "* ]]; then
        printf '%s\t\n' "$2" | cliphist decode |
            chafa -f "$([ -n "$SWAYSOCK" ] && echo sixels || echo symbols)" --animate off -s "${FZF_PREVIEW_COLUMNS}x$((FZF_PREVIEW_LINES - 2))" -
        echo; echo "$3"
    else
        printf '%s\t\n' "$2" | cliphist decode
    fi
    exit ;;
esac

if [ -n "$SWAYSOCK" ]; then msg=swaymsg; else msg=i3-msg; fi
# $1 = MIME type, or nothing for text
copy() {
    if [ -n "$SWAYSOCK" ]; then wl-copy ${1:+--type "$1"}
    else xclip -selection clipboard ${1:+-t "$1"}; fi
}

# Remember what had focus before the picker window takes it (i3 has no app_id: the class)
app=$($msg -t get_tree | jq -r '.. | select(.focused? == true) | .app_id // .window_properties.class // ""')

out=$(mktemp); trap 'rm -f "$out"' EXIT
if [ -n "$SWAYSOCK" ]; then
    foot --app-id=clipboard -o main.font='JetBrainsMono Nerd Font:size=9' -o main.pad=6x6 "$self" pick "$out"
else
    alacritty --class clipboard -o font.size=9 -o window.padding.x=6 -o window.padding.y=6 -e "$self" pick "$out"
fi
line=$(cat "$out")
[ -n "$line" ] || exit 0

id=${line%%$'\t'*}; desc=${line#*$'\t'}
if [[ $desc =~ ^\[\[\ binary\ data\ .*\ ([a-z]+)\ [0-9]+x[0-9]+\ \]\]$ ]]; then
    type=image/${BASH_REMATCH[1]/jpg/jpeg}
    printf '%s\t\n' "$id" | cliphist decode | copy "$type"
else
    printf '%s\t\n' "$id" | cliphist decode | copy
fi

sleep 0.15   # let focus return to the previous window
case "$app" in
    foot|Alacritty|scratch-*)   shift=1 ;;
    *)                          shift= ;;
esac
if [ -n "$SWAYSOCK" ]; then
    if [ -n "$shift" ]; then wtype -M ctrl -M shift -k v -m shift -m ctrl; else wtype -M ctrl -k v -m ctrl; fi
else
    xdotool key --clearmodifiers "ctrl+${shift:+shift+}v"
fi
