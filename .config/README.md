> **Personal Repository:** These are my actual configuration files. This README documents my workflow; it is not a tutorial or generic template.

# Dotfiles Bare Repository

This is a bare Git repository tracking configuration files in`$HOME` via the`config` alias.

## Setup on a New Machine

```bash
git clone --bare https://github.com/Bueezi/dotfiles.git $HOME/.dotfiles
alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
config config --local status.showUntrackedFiles no
config checkout
```

If checkout fails because files already exist, back them up first:
```bash
mkdir -p .config-backup && config checkout 2>&1 | grep -E "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
```

## Daily Usage

Use`config` exactly like`git`, but **never add the entire home directory**:

```bash
# Check status (shows only tracked files)
config status

# Add specific files explicitly
config add .bashrc .vimrc .config/nvim/init.vim

# Or update only already-tracked files (safe for bulk changes)
config add -u

# Commit and push
config commit -m "Update shell config"
config push
```

**Never run**`config add .` **from your home directory**—this stages every file in`~` including Downloads, Documents, and secrets.

## The Alias

Add to`.bashrc` or`.zshrc`:
```bash
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
```

## How It Works

This uses Git's`work-tree` feature. The bare repository lives in`~/.dotfiles` while`$HOME` acts as the working tree. The`status.showUntrackedFiles no` setting prevents`config status` from flooding your terminal with every untracked file in your home directory.
