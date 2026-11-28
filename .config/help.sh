#!/bin/sh
# help [--tmux]
b=$(printf '\033[1m') n=$(printf '\033[0m')
case $1 in
--tmux) cat <<EOF
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
;;
*) cat <<EOF
${b}Steam launch options${n}  (right-click game, Properties)
  HDR (Proton)     PROTON_ENABLE_WAYLAND=1 DXVK_HDR=1 %command%
                   quit Steam fully after changing, HDR in the game's settings
  CS2              SDL_VIDEO_ALLOW_SCREENSAVER=1 gamescope-sdl -w 1440 -h 1080 -W 2560 -H 1440 -r 180 -S stretch -f --force-grab-cursor -- gamemoderun %command%

${b}gdu${n}  disk usage
  gdu [folder]     browse sizes (default: this folder), gdu -d: all disks
  j/k  l/Enter  h  move, open folder, back
  s  n  C          sort by size / name / item count
  d                delete (asks first)
  v  i             view file, info
  q                quit, ? for every key

${b}gdb${n}  debugger (C)
  cc -g prog.c     compile with debug info, then: gdb ./prog
  b main / b 12    breakpoint at a function / line
  r [args]         run
  n  s             next line / step into the function
  c  fin           continue / run until the function returns
  p x   p *ptr     print a value, what a pointer points to
  p arr[0]@5       print 5 elements
  display x        print x after every step
  bt               where am I (call stack), after a crash too
  info locals      all local variables
  watch x          stop when x changes
  tui enable       show the source above, q quits gdb

${b}Tailscale${n}
  sudo tailscale up --accept-routes    once per machine (log in, homelab subnets)

  help --tmux      tmux and fish keys
EOF
;;
esac
