# Interactive shell. foot starts fish; bash stays the login shell and runs scripts
# (so .bashrc keeps `cu` for power.sh too).

# fish_add_path skips entries already there (fish started from fish would add them again)
fish_add_path -g ~/.cargo/bin ~/.local/bin
fish_add_path -ga ~/.lmstudio/bin

if status is-interactive
    # Light mode (darkmode.sh): switch this foot window to its [colors-light] before the first
    # prompt. foot is fish's parent (foot.ini execs fish); darkmode.sh signals windows already open
    if test "$(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null)" = "'prefer-light'"
        set -l term (ps -o ppid= -p $fish_pid | string trim)
        test "$(ps -o comm= -p $term)" = foot; and kill -USR2 $term
    end

    # "welcome ~" in the same pill as the prompt's directory, instead of "Welcome to fish"
    function fish_greeting
        echo -n ''
        set_color --reverse --bold; echo -n ' welcome ~ '
        set_color normal; echo -n ''
        set_color 555; echo '  '(date '+%a %d/%m  %H:%M')
        set_color normal
    end

    # Vim keys: Esc for normal mode. Cursor: block in normal, bar in insert
    fish_vi_key_bindings
    set -g fish_cursor_default block
    set -g fish_cursor_insert line
    set -g fish_cursor_replace_one underscore
    set -g fish_cursor_visual block
    function fish_mode_prompt; end   # starship's ❯/❮ shows the mode instead of [I]/[N]

    # Aliases live in ~/.bashrc only (add/edit them there): fish runs its `alias name='...'` lines
    for line in (string match -r '^alias \S+=.*' < ~/.bashrc)
        eval $line
    end

    # Dotfiles sync: the one cu, in .bashrc (power.sh's sync uses it too)
    function cu --description 'Sync dotfiles: commit, pull --rebase, push'
        bash -ic 'cu "$@"' cu $argv
    end

    starship init fish | source
end
