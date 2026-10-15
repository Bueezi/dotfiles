#
# ~/.bashrc
#

# Each directory once: shells started from a shell would add them again
path_add() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac; }
path_add "$HOME/.cargo/bin"
# The tablet (Termux): its launchers (desktop, debian)
[ -n "$TERMUX_VERSION" ] && path_add "$HOME/.config/termux/bin"
path_add "$HOME/.local/bin"
# LM Studio's CLI (lms), on the desktop: its installer wrote this line
[ -d "$HOME/.lmstudio/bin" ] && case ":$PATH:" in *":$HOME/.lmstudio/bin:"*) ;; *) PATH="$PATH:$HOME/.lmstudio/bin" ;; esac
export PATH
unset -f path_add
# make: all cores (its default is one job). Also in fish's config
export MAKEFLAGS="-j$(nproc)"

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
