#!/bin/sh
# $2 = ask: prompt for the program's arguments (split on spaces)
cd "$(dirname "$1")" || exit
name=$(basename "$1"); bin=${XDG_RUNTIME_DIR:-/tmp}/${name%.*}
args=
[ "$2" = ask ] && { printf 'Arguments: '; read -r args; }
case $1 in
    *.c)        gcc -g -Wall -Wextra "$1" -o "$bin" -lm && "$bin" $args ;;
    *.cpp|*.cc) g++ -g -Wall -Wextra "$1" -o "$bin" && "$bin" $args ;;
    *.rs)       rustc -g "$1" -o "$bin" && "$bin" $args ;;
    *.py)       python3 "$1" $args ;;
    *)          echo "No run command for $1"; false ;;
esac
printf '\n[exit %s]\n' "$?"
