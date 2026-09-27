# Interactive shell. foot starts fish; bash stays the login shell and runs scripts
# (so .bashrc keeps `cu` for power.sh too).

set -gx PATH ~/.cargo/bin ~/.local/bin $PATH ~/.lmstudio/bin

if status is-interactive
    set -g fish_greeting   # no "Welcome to fish"

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
