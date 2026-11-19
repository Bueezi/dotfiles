fish_add_path -g ~/.cargo/bin ~/.local/bin
fish_add_path -ga ~/.lmstudio/bin
set -gx MAKEFLAGS -j(nproc)

if status is-interactive
    # Light mode: switch this foot window to its light colours
    if test "$(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null)" = "'prefer-light'"
        set -l term (ps -o ppid= -p $fish_pid | string trim)
        test "$(ps -o comm= -p $term)" = foot; and kill -USR2 $term
    end

    function fish_greeting
        echo -n ''
        set_color --reverse --bold; echo -n ' welcome ~ '
        set_color normal; echo -n ''
        set_color 555; echo '  '(date '+%a %d/%m  %H:%M')
        set_color normal
    end

    fish_vi_key_bindings
    set -g fish_cursor_default block
    set -g fish_cursor_insert line
    set -g fish_cursor_replace_one underscore
    set -g fish_cursor_visual block
    function fish_mode_prompt; end   # starship shows the mode

    # Aliases live in ~/.bashrc only
    for line in (string match -r '^alias \S+=.*' < ~/.bashrc)
        eval $line
    end

    function f
        set -l tmp (mktemp -t yazi-cwd.XXXXXX)
        yazi $argv --cwd-file="$tmp"
        if read -z cwd < $tmp; and test -n "$cwd"; and test "$cwd" != "$PWD"
            cd -- $cwd
        end
        rm -f -- $tmp
    end

    starship init fish | source
end
