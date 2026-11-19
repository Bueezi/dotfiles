export PATH
export MAKEFLAGS="-j$(nproc)"

[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

PS1='[\u@\h \W]\$ '

alias con='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias g="git"

# make it so after quitting yazi in a folder the terminal is in that folder
f() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd"
    rm -f -- "$tmp"
}
