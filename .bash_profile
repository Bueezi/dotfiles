# Login shells (TTY, SSH) don't read .bashrc on their own, and NixOS's /etc/profile doesn't either
[[ -f ~/.bashrc ]] && . ~/.bashrc
