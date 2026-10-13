# Dotfiles

My real config (not a template): a bare Git repo `~/.dotfiles` with `$HOME` as work tree, NixOS + a SwayFX desktop on two machines. Details live in the files' own comments; this is the map and the rules.

| | Desktop | Laptop |
|---|---|---|
| Hardware | Ryzen 5 7500F, RX 9070 XT, `DP-2` 2560x1440@180 | Ryzen 7430U, `eDP-1` scale 1.35 |
| Nix | `isLaptop = false` | `isLaptop = true` |
| Scripts / sway | no `/sys/class/power_supply/BAT0` | `BAT0` exists |

NixOS 26.05, channel-based (not a flake system). Per-machine: `lib.mkIf isLaptop` / `lib.optionals (!isLaptop)` in Nix, the `BAT0` test elsewhere.

## Rules

- **Git:** `config`, never `git`, in `~`. New files: `config add <file>`, never `config add .`. Don't commit or push: I sync with `cu`.
- **Nothing in the root of `~`.** New files go under `~/.config/`. Only exceptions, because programs look nowhere else: `~/.local/share/themes/` (GTK themes) and `~/.local/bin/` (my commands, like `cu`).
- **No sudo here** (no-new-privileges). For `nixos-rebuild`, tell me to rebuild (power menu → *rebuild*).
- **Check before handing over:** `sway -C -c ~/.config/sway/config` then `swaymsg reload`; `sh -n` / `bash -n`; NixOS via a throwaway config in a scratch dir (never `~`), for both `isLaptop` values:
  ```nix
  { ... }: { imports = [ /home/ben/.configuration.nix ]; _module.args.isLaptop = false;
             fileSystems."/" = { device = "/dev/null"; fsType = "ext4"; }; }
  ```
  `nix-instantiate '<nixpkgs/nixos>' -A system -I nixos-config=<file>`. Boot-level changes: `nix-build '<nixpkgs/nixos>' -A vm`. Looks: screenshot in a headless sway (`WLR_BACKENDS=headless`, own `dbus-run-session`, `GSETTINGS_BACKEND=keyfile`, own `XDG_CONFIG_HOME`).
- **Style:** black and white everywhere I draw (bar, mako, OSD, fuzzel, fastfetch, prompt). Apps (GTK, Qt, LibreWolf) keep Adwaita's blue accent: a black accent was tried and disliked. Match the surrounding code and its short *why* comments. Small changes, not many new files.
- **Nerd Font glyphs** (private-use, e.g. U+E0B6, U+F0176) get dropped silently by some edit tools: check with a codepoint dump.

## Map

- `.configuration.nix`: the whole system (boot, hardware, sway session, login, themes, default apps, packages, gaming). Imported by the `/etc/nixos` stub `.config/scripts/configuration.nix` (sets `hostName`, `isLaptop`; fetches from GitHub on a fresh install).
- `.config/nixos/*.nix`: self-contained modules, imported only if present (`builtins.pathExists`): LibreWolf prefs/policies, SwayFX from git (`swayfx/flake.nix`, pinned; carries a patch for swayfx#557), Plymouth splash, HyprQuickPaper + wallpaper slideshow, Eclipse Music (Electron).
- `.config/sway/`: config, `i3status.toml`, `scripts/` (each script's header says what it does; `$mod+/` lists all keys).
- `.config/scripts/`: install scripts served by URL (`nix.b3n.me` → the NixOS stub; `arch.sh`/`void.sh` kept for future installs; the tablet setup will go here).
- `.local/bin/cu`: sync. Dotfiles (commit tracked changes, message = changed files, pull --rebase, push), then `~/Documents/sync`.
- `~/Documents/sync/`: separate private repo (github.com/Bueezi/sync) with **one commit only**, so deleted files leave GitHub too. Wallpapers in `wp/active/` (picker, slideshow) and `wp/inactive/`.
- Shell: bash is the login shell and runs scripts; foot starts fish + starship. **Aliases only in `.bashrc`**: fish imports its `alias` lines. `.bash_profile` is what loads `.bashrc` on TTY/SSH logins.
- Git identity and GitHub login: `.config/git/config` (plain `gh` as helper, not a store path).
- Themes: dconf `color-scheme` is the truth, `darkmode.sh` toggles. GTK3 dark = `.local/share/themes/Mono-dark` (imports adw-gtk3-dark), GTK4 = `.config/gtk-4.0/gtk.css`, Qt = qt6ct palettes in `.config/qt6ct/colors/` (`qt6ct.conf` is written by `darkmode.sh`, untracked).

## Gotchas (don't re-investigate)

- **Don't add `output * bg`:** swaybg restarts on every reload and covers awww.
- **No HDR:** scenefx disables colour transforms. **swaybar has no dbusmenu** (Steam's tray menu can't work; Electron menus go through `tray-menu.sh`). **LibreWolf** quits with its last window.
- The sway session's PATH lacks `~/.local/bin` (greetd only sources `.profile`): call `cu` by full path from scripts.
- Tried and disliked: dimming unfocused windows, Qt's `gtk3` platform theme (old greys), foot `include=` of a state file (errors when missing), `GTK_THEME` (pins one theme).
- `~/.config/xdg-desktop-portal-wlr/config` is ignored: the picker is set in Nix (`xdg.portal.wlr.settings`).
- Tailscale needs `services.resolved`, or it takes over all DNS.
- Steam games run in a sandbox with a private `/tmp`: nothing outside can talk to a running Wine app.
- Assetto Corsa: GE-Proton9-20 (Wine 10+ blocks CSP's patching), launch options `WINEDLLOVERRIDES="dwrite=n,b" %command%` (no gamescope), its prefix's `Steam/config/loginusers.vdf` symlinks to Steam's, hidden CSP caches off in the prefix's `Documents/Assetto Corsa/cfg/extension/general.ini`. `acmanager://` links (`acmanagerLinks`) work only while Content Manager is closed.

## New machine

```bash
git clone --bare https://github.com/Bueezi/dotfiles.git ~/.dotfiles
alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
config config --local status.showUntrackedFiles no
config checkout   # if files already exist: move them aside first
```
Then copy `.config/scripts/configuration.nix` to `/etc/nixos/`, set `hostName` / `isLaptop`, rebuild, and run `cu` once (clones `~/Documents/sync`).
