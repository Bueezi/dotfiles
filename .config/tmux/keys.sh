#!/bin/sh
b=$(printf '\033[1m') n=$(printf '\033[0m')
cat <<EOF
${b}tmux${n}
  Alt+n            new pane beside (same folder)
  Alt+Shift+n      new pane below (same folder)
  Alt+h/j/k/l      move to pane left/down/up/right
  Alt+z            pane fullscreen on/off
  Alt+f            pop-up terminal on/off (keeps its content)
  Alt+s            scroll mode
  Ctrl+d / exit    close pane (or the pop-up for good)

${b}Scroll mode${n}  (Alt+s or mouse wheel)
  k/j  Ctrl+u/d    line, half page
  gg / G           top / bottom
  / ?  n           search down / up, next match
  v  y             select, copy to clipboard
  q                leave

${b}Mouse${n}
  click / drag border   focus pane / resize
  drag, 2x / 3x click   copy selection, word, line
  Shift+drag            foot's selection, Ctrl+Shift+C to copy

${b}Prefix Ctrl+b, then${n}
  c  n  p          new window / next / previous
  %  "             split side by side / stacked
  x                close pane
  ?                list every key

${b}fish${n}
  Ctrl+r           search history
EOF
