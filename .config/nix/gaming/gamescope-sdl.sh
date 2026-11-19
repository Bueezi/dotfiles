# gamescope-sdl <options> -- %command%: SDL backend without Steam's LD_* (CLAUDE.md, CS2)
opts=()
while [ $# -gt 0 ] && [ "$1" != -- ]; do opts+=("$1"); shift; done
shift
exec env -u LD_PRELOAD -u LD_LIBRARY_PATH \
    gamescope --backend sdl "${opts[@]}" -- \
    env LD_PRELOAD="${LD_PRELOAD-}" LD_LIBRARY_PATH="${LD_LIBRARY_PATH-}" "$@"
