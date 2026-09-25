#
# ~/.bashrc
#

export PATH="/home/ben/.cargo/bin:$PATH"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

PS1='[\u@\h \W]\$ '

alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
# Sync dotfiles both ways: commit tracked changes, pull the other machine's, push.
# New files still need an explicit `config add <file>` first.
cu() {
    config add -u &&
    { config diff --cached --quiet || config commit -m "${1:-update}"; } &&
    config pull --rebase &&
    config push
}

alias g="git"
alias gc='gcc -std=c99 -Wall -Wextra -pedantic'

#alias hx='helix'
alias hc='hx ~/.configuration.nix'
alias hs='hx ~/.config/sway/config'
alias rb="sudo nixos-rebuild switch"
alias gitu='git commit -m "update" && git push'

# if [ "$(tty)" = "/dev/tty1" ] && [ -z "$WAYLAND_DISPLAY" ]; then
#     WLR_RENDERER=vulkan exec sway
# fi

# _host=$(hostname)
# if [ "$_host" = "void" ]; then
#     alias sudo='doas'
#     alias xi='doas xbps-install'
#     alias helix='hx'
#     alias btop='doas btop --force-utf'
# fi
export PATH=$HOME/.local/bin:$PATH
source "/home/ben/Documents/informatica_werktuigen/setup.sh"  # ctf oefenzitting Linux
