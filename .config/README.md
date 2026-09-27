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
- **Style:**
  - The look is **black and white** everywhere (bar, mako, OSD, fastfetch, fuzzel). No accent colours.
  - Match the surrounding code, including its short comments that say *why*.
  - Keep changes small. Don't spread one feature over many new files.
  - The `.nix` extras are self-contained modules imported from `.configuration.nix`.

## NixOS

| File | What |
|---|---|
| `.configuration.nix` | The shared system config: boot, hardware, audio, power, sway, packages, gaming (desktop), and more. |
| `.config/scripts/configuration.nix` | The stub that lives in `/etc/nixos/` on each machine. It sets `hostName` and `isLaptop`, and imports `~/.configuration.nix`, or fetches it from GitHub on a fresh install. |
| `.config/nixos/librewolf.nix` | Overlay that bakes prefs and policies into LibreWolf (DuckDuckGo with suggestions, no crash-restore page, Sync, passwords…). |
| `.config/nixos/swayfx.nix` + `swayfx/flake.nix` | swayfx and scenefx built from **git** against the system nixpkgs (pinned in `flake.lock`; update with `nix flake update --flake ~/.config/nixos/swayfx`). |
| `.config/nixos/plymouth.nix` + `plymouth/` | Boot splash: `boot.mp4` (penguin shooting the Windows logo) cut to frames at build time and looped by `penguin.script`. `plymouth-play-once.service` holds the login screen until it has played once, counting from when amdgpu comes up. Also turns on the quiet boot, systemd initrd and early amdgpu. |
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
- **Screen sharing:** the xdg-desktop-portal-wlr picker is set in Nix (`xdg.portal.wlr.settings`, fuzzel by full path). `.config/xdg-desktop-portal-wlr/config` is **ignored** on NixOS.

## Sway (SwayFX)

- `.config/sway/config`: variables at the top (`$term` foot, `$fm` thunar, `$menu` fuzzel, `$browser` librewolf, `$discord` vesktop), then autostart, window rules and keybinds.
- **Bar:** swaybar + i3status-rs (`.config/sway/i3status.toml`). The caffeine (signal 1) and nightlight (signal 2) badges are custom blocks that call the scripts' `status` mode.
- **Notifications:** mako (`.config/mako/config`) on the `overlay` layer, so they show over fullscreen. `app-name=osd` is the volume/brightness OSD.
- **SwayFX effects:** blur, shadows, 0.15 dimming of unfocused windows, and `layer_effects` blur behind fuzzel (`launcher`), mako (`notifications`) and the bar (`panel`). That blur only shows because their backgrounds are see-through (`#000000b3`; the i3status block backgrounds are `#00000000`).
- **Wallpaper:** `awww-daemon` (swww's new name) draws it, with an animated transition when `wallpaper.sh` switches. **Don't add `output * bg`:** swaybg restarts on every `swaymsg reload` and covers awww, so wallpaper changes stop showing.
- **Lock:** swaylock-effects (`.config/swaylock/config`): a blurred snapshot fading in (0.5s), with the clock in the ring. It's patched in `.configuration.nix` (`swaylockFx`): upstream only starts redrawing on its first clock tick, so the fade stalled on the unblurred screen for ~1s. Plain swaylock refuses these options and exits without locking.
- **Login:** tuigreet in `.configuration.nix` (a wrapper script): monochrome `--theme`, a big "nixos" greeting (lines padded to one width, since tuigreet centres each line), asterisks, and a clock.
- **Themes:** cursor Bibata-Modern-Classic and icons Papirus-Dark, set once in the `let` at the top of `.configuration.nix` (plus `seat * xcursor_theme` in the sway config and `icon-theme` in fuzzel). Qt follows the dark theme through `qt.platformTheme = "gnome"` / `style = "adwaita-dark"`.
- **Autostart:**
  - mako, the polkit agent, `sunset.sh`, the battery notifier, the clipboard watcher, LibreWolf, `idle.sh`, swayrd and `tray-menu.sh`.
  - Desktop only: Vesktop (`--start-minimized`) and Steam (`-silent`).

### Scripts (`.config/sway/scripts/`)

| Script | Key | What |
|---|---|---|
| `open.sh <mark> <w> <h> <cmd>` | `$mod+Shift+d` Vesktop, `$mod+i` Steam | Opens or toggles an app: tiled on an empty workspace, otherwise a floating scratchpad window. The same key hides it. Finds the window by a sway mark set in a `for_window` rule, and always moves it to the current workspace. |
| `screenshot.sh` | `$mod+Shift+s` | Freezes the screen (wayfreeze), region select (slurp), grim, clipboard. |
| `osd.sh` | media/brightness keys, `$mod+PageUp/PageDown` | Volume in 2% steps, brightness in 5% steps. The mako OSD shows a 25-block text bar. On the desktop, brightness goes over **DDC/CI** (ddcutil), cached with a background applier so it feels instant. |
| `power.sh` | `$mod+Shift+p` | fuzzel menu: sleep, hibernate, reboot, power off, **update**, **rebuild**, **sync** (`cu`). Update and rebuild ask for sudo first, then hide their `scratch-power` terminal and send a "started" notification. |
| `caffeine.sh` | `$mod+Shift+i` | Stops/starts swayidle, with a bar badge. |
| `nightlight.sh` / `sunset.sh` | `$mod+n` | Toggles wlsunset, with a bar badge. `sunset.sh` holds the coordinates. |
| `idle.sh` | – | swayidle: lock at 3 min, screen off at 3m10s. |
| `tray-menu.sh` | – | Electron tray menus open as windows with no app_id and no title. A `for_window` rule floats them off-screen, and this listener moves them to the top-right corner under the bar. |
| `clipboard.sh` / `clipstore.sh` | `$mod+Shift+v` | cliphist picker (foot + fzf + chafa) and the `wl-paste --watch` store (with timeouts so a dead client can't lock the history db). |
| `keybinds.sh` | `$mod+/` | Cheatsheet parsed from the config. |
| `display.sh` | `$mod+p` | Extend / mirror / single screen. |
| `audio_switch.sh`, `bluetooth.sh` | `$mod+Shift+a`, `$mod+Shift+b` | Output device picker, Bluetooth menu. |
| `record.sh`, `wallpaper.sh`, `theme.sh` | `$mod+Shift+r/w/t` | Screen recording to `~/Downloads`, wallpaper from `~/Documents/wp`, GTK theme picker. |
| `default.sh`, `battery-notify.sh` | – | Sets the default xdg apps; low-battery notifications. |

### Other keys and conventions

- **Apps:**
  - `$mod+Return`: terminal, tiled on an empty workspace, otherwise floating `scratch-float`.
  - `$mod+Shift+Return`: the one toggled `scratch-term`.
  - `$mod+Shift+e`: Thunar in the scratchpad.
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
  - `.config/fish/config.fish` has vi key bindings, the aliases and `cu`, and loads starship.
  - `.config/starship.toml` is the monochrome prompt: ❯ white, grey after an error, ❮ in vi normal mode.
  - `/bin/bash` is a tmpfiles symlink to the system bash, so `#!/bin/bash` scripts work.
  - The terminal font is Iosevka Nerd Font 12.

`foot`, `fuzzel`, `helix` (+ `languages.toml`), `swaylock`, `swaynag`, `swayr`, `networkmanager-dmenu`, `cava` (white bars; cmatrix and pipes.sh are installed too), and `fastfetch`: big NixOS logo in white/grey, `Key: value` layout, values grey `38;5;248`. `fetch` (areofyl, spinning 3D logo): built from its GitHub `main` in `.configuration.nix` and patched to black and white (`--no-color`, grey percentages); fields in `.config/fetch/config`.

Legacy, not used by the current setup: `.config/hypr/` (old Hyprland), `.config/waybar/` (not running; swaybar is the bar), and `.config/scripts/arch.sh` / `void.sh` (install notes for other distros; `power.sh` still has a Void branch).

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
