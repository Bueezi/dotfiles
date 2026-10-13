# Dotfiles

My real config (not a template): a bare Git repo `~/.dotfiles` with `$HOME` as work tree. NixOS + a SwayFX desktop on two machines, and a tablet with Termux + i3 that checks out part of it. Details live in the files' own comments; this is the map and the rules.

| | Desktop | Laptop | Tablet |
|---|---|---|---|
| Hardware | Ryzen 5 7500F, RX 9070 XT, `DP-2` 2560x1440@180 | Ryzen 7430U, `eDP-1` scale 1.35 | Honor MagicPad 4 (Snapdragon, Adreno) |
| System | NixOS, `isLaptop = false` | NixOS, `isLaptop = true` | Android: Termux + Termux:X11, i3 (X11), `termux.sh` |
| Scripts | no `/sys/class/power_supply/BAT0` | `BAT0` exists | `$TERMUX_VERSION` set; i3 = `$SWAYSOCK` unset |

NixOS 26.05, channel-based (not a flake system). Per-machine: `lib.mkIf isLaptop` / `lib.optionals (!isLaptop)` in Nix, the `BAT0` test elsewhere.

## Rules

- **Git:** `config`, never `git`, in `~`. New files: `config add <file>`, never `config add .`. Don't commit or push: I sync with `cu`.
- **Nothing in the root of `~`.** New files go under `~/.config/`. Only exceptions, because programs look nowhere else: `~/.local/share/themes/` (GTK themes) and `~/.local/bin/` (my commands, like `cu`).
- **No sudo here** (no-new-privileges). For `nixos-rebuild`, tell me to rebuild (power menu → *rebuild*).
- **Check before handing over:** `sway -C -c ~/.config/wm/sway` then `swaymsg reload`; shared i3 syntax: `i3 -C` misses bind commands, so test them in an Xvfb i3 with its own `ipc-socket` and `unset I3SOCK SWAYSOCK` first (sway exports I3SOCK: `i3-msg` would hit the real session); `sh -n` / `bash -n`; NixOS via a throwaway config in a scratch dir (never `~`), for both `isLaptop` values:
  ```nix
  { ... }: { imports = [ /home/ben/.configuration.nix ]; _module.args.isLaptop = false;
             fileSystems."/" = { device = "/dev/null"; fsType = "ext4"; }; }
  ```
  `nix-instantiate '<nixpkgs/nixos>' -A system -I nixos-config=<file>`. Boot-level changes: `nix-build '<nixpkgs/nixos>' -A vm`. Looks: screenshot in a headless sway (`WLR_BACKENDS=headless`, own `dbus-run-session`, `GSETTINGS_BACKEND=keyfile`, own `XDG_CONFIG_HOME`).
- **Style:** black and white everywhere I draw (bar, mako, OSD, fuzzel, prompt); only the distro logos in fastfetch/fetch keep their colours. Apps (GTK, Qt, LibreWolf) keep Adwaita's blue accent: a black accent was tried and disliked. Match the surrounding code and its short *why* comments. Small changes, not many new files.
- **Nerd Font glyphs** (private-use, e.g. U+E0B6, U+F0176) get dropped silently by some edit tools: check with a codepoint dump.

## Map

- `.configuration.nix`: the whole system (boot, hardware, sway session, login, themes, default apps, packages, gaming). Imported by the `/etc/nixos` stub `.config/scripts/configuration.nix` (sets `hostName`, `isLaptop`; fetches from GitHub on a fresh install).
- `.config/nixos/*.nix`: self-contained modules, imported only if present (`builtins.pathExists`): LibreWolf (reads `.config/librewolf/prefs.js` + `policies.json`, the same files the tablet links), SwayFX from git (`swayfx/flake.nix`, pinned; carries a patch for swayfx#557), Plymouth splash, HyprQuickPaper + wallpaper slideshow, Eclipse Music (Electron).
- `.config/wm/`: window manager. `common.conf` = what sway and the tablet's i3 share (looks, window keys; only syntax both accept: plain `bindsym` lines, `split h`, `60 px`), `sway` = the sway-only rest (SwayFX, outputs, rules, sway keys, bar), `i3status-rs.toml`, `scripts/` (each header says what it does; `$mod+/` lists all keys, includes followed): the ones bound in `common.conf` work in both (they branch on `$SWAYSOCK`: foot/fuzzel/wl-copy/wtype vs alacritty/rofi/xclip/xdotool), the rest are sway-only and bound in `wm/sway`. Test i3 paths in Xvfb with a fake `HOME`/`XDG_CONFIG_HOME` set *before* `dbus-run-session` (else the test bus's dconf-service writes the real dconf), and stand-ins for notify-send; clean up by PID only (the real `wl-paste --watch …/clipstore.sh` matches a `pkill -f clipstore`). `.config/sway/config` is a tracked symlink to `wm/sway`: **edit `wm/sway`**, since editors that save by renaming turn the symlink into a copy.
- `.config/scripts/`: install scripts served by URL (`nix.b3n.me` → the NixOS stub; `arch.sh`/`void.sh` kept for future installs). `termux.sh` = the tablet's setup and "rebuild": its package lists (pkg, npm, go, TeX Live collections = KU Leuven's list, proot Debian for ddd) are the source of truth like `.configuration.nix`; unlisted packages get removed after a prompt; it also does the dotfiles' sparse checkout and the source builds (clipnotify, libsensors, i3status-rs, fetch).
- `.local/bin/rb`: rebuild this machine (NixOS: `sudo nixos-rebuild switch`; tablet: `termux.sh`).
- `.local/bin/cu`: sync. Dotfiles (commit tracked changes, message = changed files, pull --rebase, push), then `~/Documents/sync`.
- `~/Documents/sync/`: separate private repo (github.com/Bueezi/sync) with **one commit only**, so deleted files leave GitHub too. Wallpapers in `wp/active/` (picker, slideshow) and `wp/inactive/`.
- Shell: bash is the login shell and runs scripts; foot starts fish + starship. **Aliases only in `.bashrc`**: fish imports its `alias` lines. `.bash_profile` is what loads `.bashrc` on TTY/SSH logins.
- Tablet: `.config/wm/i3` (+ `.config/i3/config` link), and the X11 counterparts of the sway tools: alacritty (foot), dunst (mako), rofi (fuzzel), feh + `wm/scripts/wallpaper.sh` (HyprQuickPaper/slideshow). `.config/termux/`: `bin/desktop` (starts Termux:X11 + i3 in a D-Bus session, detached; `hide`/`stop`/`exit`; log in `$PREFIX/tmp/desktop.log`; sets its own PATH since Termux:Widget gives no shell environment), `bin/pd` (proot Debian), Termux's own `termux.properties`/`colors.properties` (linked into `~/.termux` by `termux.sh`, so the PCs get no `~/.termux`). Linux-only desktop apps on the tablet: Vesktop and Claude Desktop from their arm64 `.deb`s in the proot Debian (`pd`, which also passes the D-Bus session for notifications), btop there too (`.config/termux/bin/btop`, with a `/proc/cpuinfo` that names the CPU: else it reads `/sys/devices` and Android refuses); links from the container open in Termux's LibreWolf (`$BROWSER` in `pd`), `claude://` comes back through the generated Claude entry; Eclipse with Termux's own `electron42`; rofi entries generated by `termux.sh`. `~/Documents/shared` = Android's `Documents/shared` (a link, made by `termux.sh`). `.local/bin/term` = foot or alacritty (Thunar's terminal via `.config/xfce4/helpers.rc`). Can't be run from here: only checked in Xvfb.
- Git identity and GitHub login: `.config/git/config` (plain `gh` as helper, not a store path).
- Themes: dconf `color-scheme` is the truth, `darkmode.sh` toggles. GTK3 dark = `.local/share/themes/Mono-dark` (imports `../../adw-gtk3-dark`: on NixOS a link to the system's theme made at login by `systemd.user.tmpfiles`, on the tablet downloaded; never a tracked file there, git would fight the tablet's real copy), GTK4 = `.config/gtk-4.0/gtk.css`, Qt = qt6ct palettes in `.config/qt6ct/colors/` (`qt6ct.conf` is written by `darkmode.sh`, untracked).

## Gotchas (don't re-investigate)

- **Don't add `output * bg`:** swaybg restarts on every reload and covers awww.
- **No HDR:** scenefx disables colour transforms. **swaybar has no dbusmenu** (Steam's tray menu can't work; Electron menus go through `tray-menu.sh`). **LibreWolf** quits with its last window.
- The sway session's PATH lacks `~/.local/bin` (greetd only sources `.profile`): call `cu` by full path from scripts.
- Tried and disliked: dimming unfocused windows, Qt's `gtk3` platform theme (old greys), foot `include=` of a state file (errors when missing), `GTK_THEME` (pins one theme).
- `~/.config/xdg-desktop-portal-wlr/config` is ignored: the picker is set in Nix (`xdg.portal.wlr.settings`).
- Tailscale needs `services.resolved`, or it takes over all DNS.
- Tablet compositor: xcompmgr (transparency, no blur). picom lags on Termux:X11 (no DRI3: every composited frame goes through the CPU) and flickers with xrender. No brightness in the bar: Android refuses its settings service to apps. LibreWolf's forced GPU prefs crash it (GPU process on Zink): keep software WebRender.
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
Tablet: in Termux, `curl -L https://raw.githubusercontent.com/Bueezi/dotfiles/main/.config/scripts/termux.sh | bash`, then `cu` once, then `desktop`.
