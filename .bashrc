export PATH
export MAKEFLAGS="-j$(nproc)"

[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias l='ls -lh --color=auto'
alias grep='grep --color=auto'

PS1='[\u@\h \W]\$ '

alias con='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias g="git"
alias gu='git commit -am "update $(git diff --name-only HEAD | xargs -n1 basename | paste -sd, - | sed "s/,/, /g")" && git push'
alias help='sh ~/.config/help.sh'
alias open='setsid -f xdg-open >/dev/null 2>&1'   # xdg-open waits for the app without a full desktop

# make it so after quitting yazi in a folder the terminal is in that folder
f() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd"
    rm -f -- "$tmp"
}

# output named after the first .c file, unless -o/-c/-S/-E is given
cc() {
    local a src=
    for a; do
        case $a in
            -o|-o*|-c|-S|-E) src=; break ;;
            *.c) [ -z "$src" ] && src=$a ;;
        esac
    done
    command cc -Wall -Wextra "$@" ${src:+-o "${src%.c}"}
}
