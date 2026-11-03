# Dotfiles

My real config (not a template): a bare Git repo `~/.dotfiles` with `$HOME` as work tree. NixOS + an Umbriel/Noctalia desktop on two machines, and a tablet with Termux + i3 that checks out part of it. **The tablet is on hold** (not used for a while): leave its files (`.config/termux/`, `termux.sh`, `wm/i3`, `wm/common.conf`, the i3 halves of `wm/scripts`) as they are, don't develop them further. This file is the map, the rules and the dead ends; how each part works is in that file's own header comments.

| | Desktop | Laptop | Tablet |
|---|---|---|---|
| Hardware | Ryzen 5 7500F, RX 9070 XT, `DP-2` 2560x1440@180 | Ryzen 7430U, `eDP-1` scale 1.35 | Honor MagicPad 4 (Snapdragon, Adreno) |
| System | NixOS, `isLaptop = false` | NixOS, `isLaptop = true` | Android: Termux + Termux:X11, i3 (X11), `termux.sh` |
| Scripts | no `/sys/class/power_supply/BAT0` | `BAT0` exists | `$TERMUX_VERSION` set; i3 = `$UMBRIEL_SOCKET` unset |

NixOS 26.05, channel-based (not a flake system). Per machine: `laptop.nix` / `desktop.nix` / `gaming.nix` in Nix (each one `lib.mkIf` on `isLaptop`), the `BAT0` test in scripts.

## Rules

- **Git:** `config`, never `git`, in `~`. New files: `config add <file>`, never `config add .`. Don't commit or push: I sync with `cu`.
- **Nothing in the root of `~`.** New files go under `~/.config/`. Only exceptions, because programs look nowhere else: `~/.local/share/themes/` (GTK themes) and `~/.local/bin/` (my commands, like `cu`). (`~/.configuration.nix` is the old entry point the `/etc/nixos` stubs import: it stays.)
- **No sudo here** (no-new-privileges). For `nixos-rebuild`, tell me to rebuild (power menu → *rebuild*).
- **Check before handing over:**
  - Umbriel: `umbriel config validate` (it reloads on save, so a broken file hits the running session).
  - i3 (tablet, on hold): `i3 -C` misses bind commands, so test them in an Xvfb i3 with its own `ipc-socket`. Fake `HOME`/`XDG_CONFIG_HOME` set *before* `dbus-run-session` (else the test bus's dconf-service writes the real dconf), stand-ins for notify-send, clean up by PID only.
  - Scripts: `sh -n` / `bash -n`.
  - NixOS: a throwaway config in a scratch dir (never `~`), for both `isLaptop` values, then `nix-instantiate '<nixpkgs/nixos>' -A system -I nixos-config=<file>`. Boot-level changes: `nix-build '<nixpkgs/nixos>' -A vm`.
    ```nix
    { ... }: { imports = [ /home/ben/.configuration.nix ]; _module.args.isLaptop = false;
               fileSystems."/" = { device = "/dev/null"; fsType = "ext4"; }; }
    ```
    A pure reorganisation can be proven: the system `.drv` must stay the same (sort order-sensitive lists like `systemPackages` first, or compare them as sets).
  - Looks: `umbriel-nested` (Umbriel in a window, own D-Bus session).
- **Style:** black and white everywhere I draw (prompt, terminal, the tablet's bar and menus; Noctalia themes itself from the wallpaper); only the distro logos in fastfetch/fetch keep their colours. Apps (GTK, Qt, LibreWolf) keep Adwaita's blue accent: a black accent was tried and disliked. Match the surrounding code and its short *why* comments; how something got this way belongs in git history, not in comments. Small changes, not many new files.
- **Nerd Font glyphs** (private-use, e.g. U+E0B6, U+F0176) get dropped silently by some edit tools: check with a codepoint dump.

## Map

**NixOS (the PCs)**
- `.configuration.nix`: the entry point, only a list of the parts below. Imported by the `/etc/nixos` stub `.config/scripts/configuration.nix` (sets `hostName`, `isLaptop`; on a fresh install it fetches the whole repo from GitHub).
- `.config/nixos/`, one file per topic:
  - `base.nix`: boot, network, Tailscale, users, Nix, audio, power, nix-ld/AppImage/Flatpak.
  - `noctalia.nix` + `noctalia/` (pinned flake): the desktop. Umbriel (compositor, git) + Noctalia (shell) + Noctalia Greeter (greetd), all built against the system nixpkgs (Umbriel gets its own wlroots 0.20.2). Umbriel's config: `.config/umbriel/config.toml` (includes the packaged one, then only my changes; reloads on save, `umbriel config validate`); its keybind helpers: `.config/umbriel/run.sh`. Noctalia does wallpaper, notifications, night light, idle/lock, clipboard, battery, brightness (ddcutil on the desktop), network/Bluetooth/audio panels, polkit. Noctalia's config: `.config/noctalia/config.toml` (shared by both machines: no per-machine includes, a missing include is fatal); Settings/IPC write `~/.local/state/noctalia/settings.toml` (untracked, wins over it), so move changes worth keeping into config.toml. `umbriel-nested`: Umbriel in a window.
  - `session.nix`: what the desktop runs on: keyring, portals (GTK next to Umbriel's), themes, cursor (the greeter reads it from here), default apps, fonts, Thunar, the tools `wm/scripts` call.
  - `packages.nix`: apps and CLI tools. `dev.nix`: editors, language servers, containers, Android, Lean (elan), KU Leuven's LaTeX.
  - `laptop.nix`, `desktop.nix` (drives, RGB, monitor, GPU, LM Studio), `gaming.nix` (Steam, Protons, G920, Assetto Corsa links, `steam-rpc.py` for Discord).
  - Self-contained extras: `librewolf.nix` (bakes in `.config/librewolf/prefs.js` + `policies.json`, the files the tablet links), `plymouth.nix` (boot splash), `webapps.nix` + `webapps/` (YouTube Music as an Electron app, see `webapp.js`; ads blocked by its `block` list and `ytmusic/preload.js`; Discord presence: `ytmusic/discord.js`).
- `.config/scripts/`: install scripts served by URL (`nix.b3n.me` → the NixOS stub; `termux.sh`; `arch.sh`/`void.sh` kept for future installs).
- `.local/bin/rb`: rebuild (`nixos-rebuild switch`, `nvd diff`, VSCodium extensions, Lean's default toolchain, Flatpak apps in `.config/flatpak/apps`); `rb -u` upgrades. On the tablet it runs `termux.sh`. Power menu (PCs and tablet): *rebuild* = `cu` then `rb`, *update* = `cu` then `rb -u` and the rest; a failed `cu` doesn't stop them.

**Scripts and the tablet's WM** (`.config/wm/`)
- `scripts/`: each header says what it does. Used under Umbriel: `power.sh`, `screenshot.sh` (ocr), `record.sh`, `idle.sh` (Noctalia's sleep), `darkmode.sh apply` (Noctalia's `theme_mode_changed` hook). The rest are the tablet's; some still have dead sway branches (`$SWAYSOCK`), left alone while the tablet is on hold.
- `i3` + `common.conf` (once shared with sway) + `i3status-rs.toml`: the tablet's i3 (started with `-c` by `desktop`).

**Tablet** (`.config/termux/`, `.config/scripts/termux.sh`)
- `termux.sh`: setup and "rebuild" (`rb`, `rb -u`); its package lists are the source of truth like the Nix files. Install: `curl -L https://raw.githubusercontent.com/Bueezi/dotfiles/main/.config/scripts/termux.sh | bash`.
- `bin/`: `desktop` (Termux:X11 + i3), `debian` (proot Debian: ddd, btop, Lean, Claude Code), launchers for the Electron apps (Vesktop, Claude Desktop, webapps), wrappers (`rofi`, `alacritty`, `xdg-open`, `lean`).
- `claude-code` + `dns-relay` + `resolv.conf`: Claude Desktop's Code tab through the proot Debian, with Android's DNS.
- X11 tools: alacritty, dunst, rofi, feh + `wm/scripts/wallpaper.sh`.

**Shared**
- Shell: bash is the login shell and runs scripts; foot starts fish + starship. **Aliases only in `.bashrc`**: fish imports its `alias` lines. `.bash_profile` loads `.bashrc` on TTY/SSH logins.
- `.local/bin/cu`: sync (dotfiles, then `~/Documents/sync`: a private repo with one commit only, wallpapers in `wp/active/`; both sides are compared with `refs/sync/base`, the last commit they agreed on). `term`: foot or alacritty. `copy`: stdin/files into the clipboard.
- VSCodium (PCs) / Code - OSS (tablet): one `.config/VSCodium/User/settings.json`; extensions listed in `.config/VSCodium/extensions`, installed by `rb`/`termux.sh`. Lean is done there (Helix has no goal view); `ELAN_HOME=~/.local/share/elan` everywhere.
- Git identity and GitHub login: `.config/git/config`.
- Themes: dconf `color-scheme` is the truth; Noctalia toggles it (Mod+Shift+T) and its `theme_mode_changed` hook runs `darkmode.sh apply` for the rest (GTK3 theme, icons, qt6ct, open foot windows); `darkmode.sh` toggles on the tablet. GTK3 dark = `.local/share/themes/Mono-dark` (imports `../../adw-gtk3-dark`: on NixOS a link made at login, on the tablet downloaded; never tracked), GTK4 = `.config/gtk-4.0/gtk.css`, Qt = qt6ct palettes in `.config/qt6ct/colors/` (`qt6ct.conf` is written by `darkmode.sh`, untracked).

## Gotchas (don't re-investigate)

**PCs**
- **Umbriel's cursor** must match dconf's (`session.nix` `cursorTheme`/`cursorSize`, which writes Umbriel's `[input.cursor]` to `share/umbriel/cursor.toml`, an optional include): its default is 24 and apps then draw a different one. `umbriel windows --json`: `active` is the window with keyboard focus, `focused` only the one focused on its workspace. Apps can't focus themselves on Wayland (Electron's `win.focus()` does nothing): focus through `umbriel msg window-focus` (`run.sh`). Umbriel/Noctalia are young: config keys can change on `nix flake update`. Umbriel suspends windows on hidden workspaces (no frame callbacks): gamescope then stalls the game (CS2 lost its game sounds in the background), fixed with a `background_render` rule.
- **LibreWolf** quits with its last window.
- `~/.local/bin` is in the session's PATH (`environment.localBinInPath`, from `/etc/profile`, which greetd sources): scripts call `rb`/`cu` by name.
- Tried and disliked: dimming unfocused windows, Qt's `gtk3` platform theme (old greys), foot `include=` of a state file (errors when missing), `GTK_THEME` (pins one theme), zathura (Evince everywhere).
- Tailscale needs `services.resolved`, or it takes over all DNS.
- **rb speed:** whatever isn't on cache.nixos.org gets built on every nixpkgs update. Avoid overrides of big packages (`papirusGrey` links instead of rebuilding Papirus). Already avoided: fish's generated completions, the man page index, the NixOS manual. Outside fetches are pinned (rev + hash), except Claude Desktop's flake (latest on purpose). Still built locally: Umbriel/Noctalia/its greeter (and Umbriel's wlroots), the TeX Live set, unfree repackaging (Steam, Claude, LM Studio).
- YouTube Music keeps Electron's own user agent: Google then serves its embedded-browser sign-in (`WebLiteSignIn`); a Chrome one gets the full flow, which rejects Electron as "may not be secure".
- Steam games run in a sandbox with a private `/tmp`: nothing outside can talk to a running Wine app.
- Discord (Vesktop's arRPC) detects games by process name from Discord's list, which often has only the Windows `.exe`: native Linux games get it from `steam-rpc.py` (Steam's log + arRPC's IPC socket).
- CS2 (4:3 stretched) runs in `gamescope-sdl` (`gaming.nix`): gamescope's default Wayland backend never pastes the desktop clipboard in, and slowed CS2 to ~120 fps / 50 ms with coloured noise lines after ~25 minutes. Its SDL backend breaks under Steam's `LD_LIBRARY_PATH` (the runtime's libSDL2) and `LD_PRELOAD`, and with `gamemoderun` in front of gamescope: the wrapper strips both for gamescope only, and gamemoderun goes after `--`.
- Assetto Corsa: Valve's Proton 9.0 from Steam (Wine 10+ blocks CSP's patching; GE-Proton9-20 crashed on NoHesi's server videos: its DXVK can't open shared textures), launch options `STEAM_COMPAT_LAUNCHER_SERVICE=proton WINEDLLOVERRIDES="dwrite=n,b;tabtip.exe=d" %command%` (Proton's tabtip, the Deck keyboard helper, turns on UI Automation, and CM's WPF tables then crash) (no gamescope; the launcher service is how `acmanager://` links reach an open Content Manager, see `gaming.nix`), its prefix's `Steam/config/loginusers.vdf` symlinks to Steam's, hidden CSP caches off in the prefix's `Documents/Assetto Corsa/cfg/extension/general.ini`. The prefix was made by a Wine 10 Proton: its leftover `winedmo.dll` crashed AC when NoHesi's server scripts opened media (moved to `compatdata/244210/winedmo-fix-backup-2026-10-30`, `winegstreamer.dll` re-registered with `wine64 regsvr32`); if media still breaks, recreate the prefix under GE-Proton9-20. Crash traces: `PROTON_LOG=1 PROTON_LOG_DIR=/home/ben/.cache` in the launch options.
- Compiled Lean programs fail inside Claude Desktop's FHS sandbox (its `/usr/lib` glibc is newer): run them from foot/VSCodium.

**Tablet** (can't be run from here: only checked in Xvfb)
- **A frozen desktop is Honor's battery manager** freezing Termux (15-30 s after a start from the widget; opening Termux wakes it): the fix is in Android's settings for Termux. It was long blamed on xcompmgr.
- Termux empties `$PREFIX/tmp` when it starts: logs that must survive go in `~/.cache`; `desktop` kills leftover pulseaudios.
- Termux:X11 resets X when its last client leaves (that wiped `Xft.dpi` before i3 connected): `termux-x11 -noreset`. i3bar/dunst sizes are at 96 dpi and double at 192; dunst's `offset` clears the bar by hand (i3 reserves nothing).
- Compositor: xcompmgr (no blur). picom slowed the whole desktop, even with no config and xrender.
- GPU: Termux's own `mesa` (26) with `MESA_VK_WSI_DEBUG=sw` (its DRI3 path left stale glyphs). LibreWolf: software WebRender capped at 60 fps (hardware was slower: frames go back through the CPU; TUR's old `mesa-zink` crashed it). Alacritty on llvmpipe (typing felt quicker; its shells get Zink back). rofi ignores Xft.dpi: wrapper passes `-dpi`.
- Microphone: pulseaudio's `module-sles-source` records zeros until Termux's own window has been in front since its service started (`desktop` shows Termux first). Exiting Termux wipes it: `desktop stop` + `desktop`.
- No brightness in the bar (Android refuses its settings service). i3bar paints block backgrounds over its own: use `none`, not a clear colour. No `tray_output primary` (no primary output). `tray-spacer.c` keeps tray icons out of the round corner.
- Keyboard case (iPad layout): `keymap.xkb` swaps left Alt/Super, top left = Esc, Caps Lock = `` ` ``; needs Termux:X11's `preferScancodes`. $mod+Shift+s is Android's screenshot: $mod+Shift+a there. The fn layer goes to Android.
- Electron's single-instance lock fails on Termux: the web apps use their own socket. Claude Desktop: its native module (glibc) can't load, nor can its terminal (node-pty) or sandbox. Its `CLAUDE_CODE_LOCAL_BINARY` override is compiled out of release builds, and glibc-runner reportedly segfaults: hence `claude-code` in the proot Debian.
- Go's cache: `GOPATH=~/.cache/go`. Helix's grammars are a separate package (`helix-grammars`). Termux's Chromium `.desktop` has unfilled `@@` placeholders: `termux.sh` writes a fixed copy.

## New machine

```bash
git clone --bare https://github.com/Bueezi/dotfiles.git ~/.dotfiles
alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
config config --local status.showUntrackedFiles no
config checkout   # if files already exist: move them aside first
```
Then copy `.config/scripts/configuration.nix` to `/etc/nixos/`, set `hostName` / `isLaptop`, rebuild, and run `cu` once (clones `~/Documents/sync`).
Tablet: run the `termux.sh` install line above in Termux, then `cu` once, then `desktop`.
