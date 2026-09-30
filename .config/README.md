> **Personal Repository:** These are my actual configuration files. This README documents my setup and workflow; it is not a tutorial or generic template. It's also written so an AI agent starting a new chat can read it and know how everything fits together.

# Dotfiles

A bare Git repo (`~/.dotfiles`) with `$HOME` as the work tree, driven by the `config` alias. It holds my NixOS config and a SwayFX desktop, shared by two machines.

## Machines

| | Desktop | Laptop |
|---|---|---|
| Hardware | Ryzen 5 7500F, RX 9070 XT (RDNA4), MSI G272QPF E2 on `DP-2` (2560x1440@180) | Ryzen 7430U, `eDP-1` (scale 1.35) |
| `isLaptop` | `false` | `true` |
| Detected in scripts by | no `/sys/class/power_supply/BAT0` | `BAT0` exists |

Both run NixOS 26.05 (channel-based, not a flake system) with the same config. Anything per-machine is switched on `isLaptop` in Nix (`lib.mkIf isLaptop`, `lib.optionals (!isLaptop)`), or on `BAT0` in the sway config and scripts.

## Rules for working on this repo (agents read this)

- **Git:** always `config`, never `git` in `~`. **New files must be staged** with `config add <file>`. Never `config add .`. Don't commit or push: I sync myself with `cu` (see `.bashrc`) or the power menu's *sync*.
- **Nothing in the root of `~`:** no new files directly in `/home/ben` (no `~/CLAUDE.md` etc.). New files go under `~/.config/`.
- **No sudo in the agent sandbox:** "no new privileges" is set, so `sudo nixos-rebuild switch` can't run from Claude Code. Tell me to rebuild: in my own terminal, or power menu → *rebuild*.
- **Check before handing over:**
  - Sway: `sway -C -c ~/.config/sway/config`, then `swaymsg reload` to apply live.
  - Shell scripts: `sh -n` / `bash -n`.
  - NixOS: evaluate without root through a throwaway test config (in a scratch dir, never in `~`):
    ```nix
    { ... }: {
      imports = [ /home/ben/.configuration.nix ];
      _module.args.isLaptop = false;
      fileSystems."/" = { device = "/dev/null"; fsType = "ext4"; };
    }
    ```
    `nix-instantiate '<nixpkgs/nixos>' -A system -I nixos-config=<that file>`.
  - Bigger boot-level changes (the Plymouth splash, for example) can be tested in a VM with `nix-build '<nixpkgs/nixos>' -A vm`.
  - Looks (themes, prompt): screenshot apps in a throwaway headless sway (`WLR_BACKENDS=headless`, own `dbus-run-session`, `GSETTINGS_BACKEND=keyfile` with its own `XDG_CONFIG_HOME`) so nothing touches my screen or dconf. Apps started without that `XDG_CONFIG_HOME` still write their config into `~/.config`.
- **Style:**
  - The look is **black and white** everywhere (bar, mako, OSD, fastfetch, fuzzel). No accent colours there. Apps (GTK, Qt, LibreWolf) keep Adwaita's **blue** accent for selections, buttons and links: a black/white accent was tried and disliked.
  - Match the surrounding code, including its short comments that say *why*.
  - Keep changes small. Don't spread one feature over many new files.
  - The `.nix` extras are self-contained modules imported from `.configuration.nix`.

## NixOS

| File | What |
|---|---|
| `.configuration.nix` | The shared system config: boot, hardware, audio, power, sway, themes, default apps (`xdg.mime`), git identity, packages, gaming (desktop), and more. |
| `.config/scripts/configuration.nix` | The stub that lives in `/etc/nixos/` on each machine. It sets `hostName` and `isLaptop`, and imports `~/.configuration.nix`, or fetches it from GitHub on a fresh install. |
| `.config/nixos/librewolf.nix` | Overlay that bakes prefs and policies into LibreWolf (DuckDuckGo with suggestions, no crash-restore page, Sync, passwords…). Rice: vertical tabs, compact density, and the "Dark space" theme installed by policy. `.config/librewolf/chrome/userChrome.css` makes the page float as a rounded panel; a user activation script symlinks that folder into each profile as `chrome` (profile names are random). |
| `.config/nixos/swayfx.nix` + `swayfx/flake.nix` | swayfx and scenefx built from **git** against the system nixpkgs (pinned in `flake.lock`; update with `nix flake update --flake ~/.config/nixos/swayfx`). |
| `.config/nixos/plymouth.nix` + `plymouth/` | Boot splash: `boot.mp4` (penguin shooting the Windows logo) cut to frames at build time and looped by `penguin.script`. `plymouth-play-once.service` holds the login screen until it has played once, counting from when amdgpu comes up. Also turns on the quiet boot, systemd initrd and early amdgpu. |
| `.config/nixos/hyprquickpaper.nix` | HyprQuickPaper wallpaper picker (Quickshell, Classic layout), pinned from GitHub and set up for awww: white border, `any` transition, and it updates `~/.local/state/wallpaper` so the pick survives login. Lists every image under `~/Documents/wp/active/`, subfolders included: `hyprquickpaper/recursive.patch` swaps the layout's one-folder `FolderListModel` for a `find` list (Classic only). Command `hyprquickpaper`, `$mod+Shift+w`. Also the **slideshow**: a systemd user timer that picks a random wallpaper from the same folder every 5 minutes, no other rules. Turning it on swaps the wallpaper right away. Toggled with `$mod+Shift+o` (`power.sh slideshow`, not in the menu); the on/off state is `~/.config/slideshow`, which sway checks at login. |
| `.config/nixos/eclipse.nix` + `eclipse/` | Eclipse Music (`eclipsemusic.app/web`) as an Electron app (`main.js`): tray icon, closing hides it, single instance (launching again toggles it). Command `eclipse`. |

The extras are imported with `builtins.pathExists`, so a fresh install without dotfiles still builds.

Notable system bits:
- **AppImages:** run through `programs.appimage`. The `extraPkgs` add `mpv-unwrapped` and `webkitgtk_4_1` for Nuvio (`~/AppImages`, managed by Gear Lever).
- **Desktop only:**
  - Steam, gamescope, gamemode, LACT, the G920 wheel (usb-modeswitch + oversteer udev).
  - `rgb-off.service`: OpenRGB turns the RGB off. Needs `i2c-dev`, with `spd5118` blacklisted so OpenRGB can see the DDR5 sticks.
  - `hardware.i2c` + `ddcutil`: monitor brightness over DDC/CI.
  - LM Studio, whose `~/.lmstudio` is a symlink to `/mnt/nvme/Documents/lm-studio`.
  - The `/mnt/nvme` and `/mnt/hdd` mounts.
- **Laptop only:** power-profile switching on AC/battery, lid → suspend-then-hibernate, and the Realtek rtw89 Wi-Fi fixes.
- **Screen sharing:** the xdg-desktop-portal-wlr picker is set in Nix (`xdg.portal.wlr.settings`, fuzzel by full path). The portal gets that file via `--config`, so a `~/.config/xdg-desktop-portal-wlr/config` would be ignored.

## Sway (SwayFX)

- `.config/sway/config`: variables at the top (`$term` foot, `$fm` thunar, `$menu` fuzzel, `$browser` librewolf, `$discord` vesktop), then autostart, window rules and keybinds.
- **Bar:** swaybar + i3status-rs (`.config/sway/i3status.toml`). The caffeine (signal 1) and nightlight (signal 2) badges are custom blocks that call `toggle.sh <name> status`. Brightness: the `backlight` block on the laptop; on the desktop a custom block (signal 3) that shows the monitor's DDC/CI level from `osd.sh brightness status`.
- **Notifications:** mako (`.config/mako/config`) on the `overlay` layer, so they show over fullscreen. `app-name=osd` is the volume/brightness OSD.
- **SwayFX effects:** blur, shadows, no dimming of unfocused windows (tried, disliked), centred title bars without the separator line (tabbed/stacked), and `layer_effects` blur behind fuzzel (`launcher`), mako (`notifications`) and the bar (`panel`). That blur only shows because their backgrounds are see-through (`#000000b3`; the i3status block backgrounds are `#00000000`).
- **Wallpaper:** `awww-daemon` (swww's new name) draws it, with an animated transition when HyprQuickPaper switches. **Don't add `output * bg`:** swaybg restarts on every `swaymsg reload` and covers awww, so wallpaper changes stop showing.
- **Lock:** swaylock-effects (`.config/swaylock/config`): a blurred snapshot fading in (0.5s), with the clock in the ring. It's patched in `.configuration.nix` (`swaylockFx`): upstream only starts redrawing on its first clock tick, so the fade stalled on the unblurred screen for ~1s. Plain swaylock refuses these options and exits without locking.
- **Login:** tuigreet in `.configuration.nix` (a wrapper script): monochrome `--theme`, a big "nixos" greeting (lines padded to one width, since tuigreet centres each line), asterisks, and a clock.
- **Themes:** dark by default, `$mod+Shift+t` (`darkmode.sh`) toggles light/dark. Dconf's `color-scheme` is the source of truth; the bar, fuzzel, mako and swaylock stay black either way.
  - GTK3: `adw-gtk3` in light mode; `Mono-dark`, built in the `let` of `.configuration.nix` on top of adw-gtk3-dark, in dark: pure black backgrounds instead of Adwaita's grey, blue accent kept. LibreWolf takes its text-selection colour from this theme. GTK4/libadwaita: the same colours in `.config/gtk-4.0/gtk.css` (`@media (prefers-color-scheme: dark)`). No `GTK_THEME` variable: it would pin one theme.
  - Qt (all Qt6): Fusion with the palettes in `.config/qt6ct/colors/` (`mono.conf`, `mono-dark.conf`) through qt6ct. `darkmode.sh` writes `qt6ct.conf` (untracked, rewritten with `mv` so running apps reload). Qt's own `gtk3` platform theme was tried: it ignores the GTK colours and falls back to old Adwaita greys.
  - foot: `[colors-dark]` / `[colors-light]`. `darkmode.sh` signals running foots (SIGUSR1/2); a new window is switched by fish at startup (`config.fish` reads dconf and signals its parent foot). No `include=` of a state file: foot errors when it's missing (it was, on the laptop). `darkmode.sh apply` (sway autostart) writes `qt6ct.conf` from dconf.
  - Icons Papirus (grey folders, `papirus-icon-theme.override`), `Papirus-Dark` in dark mode; cursor Bibata-Modern-Classic. Both in the `let` at the top of `.configuration.nix` (plus `seat * xcursor_theme` in the sway config and `icon-theme` in fuzzel).
- **Autostart:**
  - mako, the polkit agent, `sunset.sh`, the battery notifier, the clipboard watcher, LibreWolf, `darkmode.sh apply`, `idle.sh`, swayrd and `tray-menu.sh`.
  - Desktop only: Vesktop (`--start-minimized`) and Steam (`-silent`).

### Scripts (`.config/sway/scripts/`)

| Script | Key | What |
|---|---|---|
| `open.sh <mark> <w> <h> <cmd>` | `$mod+Shift+d` Vesktop, `$mod+i` Steam | Opens or toggles an app: tiled on an empty workspace, otherwise a floating scratchpad window. The same key hides it. Finds the window by a sway mark set in a `for_window` rule, and always moves it to the current workspace. |
| `screenshot.sh` | `$mod+Shift+s`, `$mod+Shift+x` | Freezes the screen (wayfreeze), region select (slurp), grim, clipboard. `$mod+Shift+x` (`ocr`): the region's **text** to the clipboard instead (tesseract, eng/fra/nld; grabbed at 2x for accuracy). |
| `osd.sh` | media/brightness keys, `$mod+PageUp/PageDown` | Volume in 2% steps, brightness in 5% steps, media keys through playerctl. The mako OSD shows a 25-block text bar. On the desktop, brightness goes over **DDC/CI** (ddcutil), cached with a background applier so it feels instant; `brightness status` prints that level for the bar. |
| `power.sh` | `$mod+Shift+p` | fuzzel menu: sleep, hibernate (laptop only: the desktop has only zram swap), reboot, power off, **update**, **rebuild**, **sync** (`cu`). Update and rebuild ask for sudo first, then hide their `scratch-power` terminal and send a "started" notification. |
| `toggle.sh caffeine` | `$mod+Shift+i` | Stops/starts swayidle (`idle.sh`), with a bar badge. |
| `toggle.sh nightlight` / `sunset.sh` | `$mod+n` | Stops/starts wlsunset, with a bar badge. `sunset.sh` holds the coordinates. |
| `idle.sh` | – | swayidle: lock at 3 min, screen off at 3m10s. The idle lock has a 5s `--grace`: touching the mouse or keyboard dismisses it without the password (manual and before-sleep locks don't). |
| `tray-menu.sh` | – | Electron tray menus open as windows with no app_id and no title. A `for_window` rule floats them off-screen, and this listener moves them to the top-right corner under the bar. |
| `clipboard.sh` / `clipstore.sh` | `$mod+Shift+v` | cliphist picker (foot + fzf + chafa) and the `wl-paste --watch` store (with timeouts so a dead client can't lock the history db). |
| `keybinds.sh` | `$mod+/` | Cheatsheet parsed from the config. |
| `display.sh` | `$mod+p` | Extend / mirror / single screen. |
| `audio_switch.sh`, `bluetooth.sh` | `$mod+Shift+a`, `$mod+Shift+b` | Output device picker, Bluetooth menu. |
| `darkmode.sh` | `$mod+Shift+t` | Light/dark toggle, see Themes above. |
| `record.sh` | `$mod+Shift+r` | Screen recording to `~/Downloads`. (`$mod+Shift+w`: HyprQuickPaper, see NixOS.) |
| `battery-notify.sh` | – | Low-battery notifications. |

### Other keys and conventions

- **Apps:**
  - `$mod+Return`: terminal (normal, tiled).
  - `$mod+Shift+Return`: a **new** floating terminal every press (`scratch-float`, in the scratchpad; `$mod+minus` hides it).
  - `$mod+Shift+e`: a **new** floating Thunar every press (in the scratchpad).
  - `$mod+x`: LibreWolf.
  - `$mod+m`: Eclipse.
  - `$mod+d`: fuzzel.
  - `$mod+Shift+n`: Wi-Fi.
- **Windows and system:**
  - `$mod+minus`: show/hide the scratchpad. `$mod+Shift+minus`: send the focused window to the scratchpad.
  - `$mod+v` / `$mod+c`: split horizontal/vertical.
  - `$mod+q`: kill.
  - `$mod+Escape`: lock.
  - `Print`: suspend.
- **Scratchpad rule:** any app_id `scratch-*` (and Thunar) opens floating in the scratchpad, shown. Power-menu terminals use `scratch-power`.
- **New windows land where the app started:** sway puts them on the workspace the app was *started* from, which for autostarted apps is the login workspace. `open.sh` moves them to the current workspace for this reason.

## Other configs

- **Shell:** bash stays the login shell and runs scripts (and keeps `cu` for `power.sh`).
  - foot starts **fish** (`shell=` in `foot.ini`, falling back to bash if fish is missing).
  - `.config/fish/config.fish` has vi key bindings and loads starship. **Aliases and `cu` live in `.bashrc` only:** fish runs `.bashrc`'s `alias` lines at startup, and its `cu` calls the bash one. Add or edit aliases in `.bashrc`, never in `config.fish`.
  - `.config/starship.toml`: two-line prompt, the directory in an `inverted` pill (white in dark mode, black in light), git/nix/duration in grey, exit code and time on the right. ❯ grey after an error, ❮ in vi normal mode. fish greets with a matching `welcome ~` pill.
  - The Nerd Font glyphs (pill caps U+E0B6/E0B4, git U+E0A0, nix U+F313) are private-use characters that some editing tools drop silently: check them with a codepoint dump after editing.
  - `/bin/bash` is a tmpfiles symlink to the system bash, so `#!/bin/bash` scripts work.
  - The terminal font is Iosevka Nerd Font 12.

`foot`, `fuzzel`, `helix` (+ `languages.toml`), `swaylock`, `swaynag`, `swayr`, `networkmanager-dmenu`, `cava` (white bars; cmatrix and pipes.sh are installed too), and `fastfetch`: big NixOS logo in white/grey, `Key: value` layout, values grey `38;5;248`. `fetch` (areofyl, spinning 3D logo): built from its GitHub `main` in `.configuration.nix` and patched to black and white (`--no-color`, grey percentages); fields in `.config/fetch/config`.

Legacy, not used by the current setup: `.config/scripts/arch.sh` / `void.sh` (install notes for other distros).

## Known limitations (don't re-investigate)

- **No HDR:** swayfx's scenefx renderer disables output colour transforms, so `output hdr on` does nothing. HDR would need plain sway with the Vulkan renderer.
- **swaybar has no dbusmenu:** tray items that only publish a menu don't work on click, notably **Steam** (right-click does nothing). Fixing it means switching to waybar. Electron apps work through `tray-menu.sh`.
- **LibreWolf** quits when its last window closes. There's no background mode on Linux.
- **Website-as-app:** LibreWolf has no install-as-app. Eclipse uses a small Electron wrapper instead.

## Setup on a new machine

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

Then put `.config/scripts/configuration.nix` in `/etc/nixos/configuration.nix`, set `hostName` / `isLaptop` in it, and rebuild.

## Daily usage

```bash
config status              # only tracked files
config add <file>          # new files: always explicitly
config add -u              # everything already tracked
cu "message"               # commit tracked changes, pull --rebase, push (from .bashrc)
```

**Never run** `config add .` in `~`: it would stage everything, including Downloads, Documents and secrets. `status.showUntrackedFiles no` keeps `config status` quiet about the rest of `~`.
