path_add() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac; }
path_add "$HOME/.cargo/bin"
path_add "$HOME/.local/bin"
[ -d "$HOME/.lmstudio/bin" ] && case ":$PATH:" in *":$HOME/.lmstudio/bin:"*) ;; *) PATH="$PATH:$HOME/.lmstudio/bin" ;; esac
export PATH
unset -f path_add
export MAKEFLAGS="-j$(nproc)"

[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

PS1='[\u@\h \W]\$ '

alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

alias g="git"
alias gc='gcc -std=c99 -Wall -Wextra -pedantic'

alias hc='hx ~/.config/nix'
alias hs='hx ~/.config/umbriel/config.toml'
alias gitu='git commit -m "update" && git push'

# Aliases only here: fish imports them. f: yazi, then cd to where it quit (also in fish's config)
f() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd"
    rm -f -- "$tmp"
}
