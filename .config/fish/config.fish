# Interactive shell. foot starts fish; bash stays the login shell and runs scripts
# (so .bashrc keeps `cu` for power.sh too).

set -gx PATH ~/.cargo/bin ~/.local/bin $PATH ~/.lmstudio/bin

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

    alias config 'git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
    alias g git
    alias gc 'gcc -std=c99 -Wall -Wextra -pedantic'
    alias hc 'hx ~/.configuration.nix'
    alias hs 'hx ~/.config/sway/config'
    alias rb 'sudo nixos-rebuild switch'
    alias gitu 'git commit -m "update" && git push'

    # Sync dotfiles both ways: commit tracked changes, pull the other machine's, push.
    # New files still need an explicit `config add <file>` first. (Same as cu in .bashrc)
    function cu --description 'Sync dotfiles: commit, pull --rebase, push'
        set -l msg update
        set -q argv[1]; and set msg $argv[1]
        config add -u
        and begin
            config diff --cached --quiet; or config commit -m $msg
        end
        and config pull --rebase
        and config push
    end

    starship init fish | source
end
