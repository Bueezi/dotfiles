#
# ~/.bashrc
#

export PATH="$HOME/.cargo/bin:$PATH"
# The tablet (Termux): its launchers (desktop, pd)
[ -n "$TERMUX_VERSION" ] && export PATH="$HOME/.config/termux/bin:$PATH"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

PS1='[\u@\h \W]\$ '

alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'   # sync: cu (~/.local/bin/cu)

alias g="git"
alias gc='gcc -std=c99 -Wall -Wextra -pedantic'

alias hc='hx ~/.configuration.nix'
alias hs='hx ~/.config/wm/sway'
alias gitu='git commit -m "update" && git push'

export PATH=$HOME/.local/bin:$PATH

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/ben/.lmstudio/bin"
# End of LM Studio CLI section
