# Dotfiles

My real config (not a template): a bare Git repo `~/.dotfiles` with `$HOME` as work tree. NixOS + an Umbriel/Noctalia desktop on two machines. This file is the map, the rules, the dead ends and the *why*: the files themselves carry only short comments.

| | Desktop | Laptop |
|---|---|---|
| Hardware | Ryzen 5 7500F, RX 9070 XT, `DP-2` 2560x1440@180 | Ryzen 7430U, `eDP-1` scale 1.35 |
| System | NixOS, `isLaptop = false` | NixOS, `isLaptop = true` |
| Boot | LUKS (`cryptroot`), Secure Boot, TPM2 unlock | same |
| Scripts | no `/sys/class/power_supply/BAT0` | `BAT0` exists |

NixOS 26.05, channel-based (not a flake system). Per machine: `laptop.nix` / `desktop.nix` / `gaming.nix` in Nix (each one `lib.mkIf` on `isLaptop`), the `BAT0` test in scripts.

## Rules

- **Git:** `config`, never `git`, in `~`. New files: `config add <file>`, never `config add .`. Don't commit or push: I sync with `cu`.
- **Nothing in the root of `~`.** New files go under `~/.config/`. Only exceptions, because programs look nowhere else: `~/.local/share/themes/` (GTK themes) and `~/.local/bin/` (my commands, like `cu`).
- **Never delete `.config/scripts/arch.sh` or `void.sh`**, even when they look unused: kept for future installs.
- **No sudo here** (no-new-privileges). For `nixos-rebuild`, tell me to rebuild (power menu → *rebuild*).
- **Check before handing over:**
  - Umbriel: `umbriel config validate` (it reloads on save, so a broken file hits the running session).
  - Scripts: `sh -n` / `bash -n`.
  - NixOS: a throwaway config in a scratch dir (never `~`), for both `isLaptop` values, then `nix-instantiate '<nixpkgs/nixos>' -A system -I nixos-config=<file>`. Boot-level changes: `nix-build '<nixpkgs/nixos>' -A vm`.
    ```nix
    { ... }: { imports = [ /home/ben/.config/nix/header.nix ]; _module.args.isLaptop = false;
               fileSystems."/" = { device = "/dev/null"; fsType = "ext4"; }; }
    ```
    A pure reorganisation can be proven: the system `.drv` must stay the same (sort order-sensitive lists like `systemPackages` first, or compare them as sets).
  - Looks: `umbriel-nested` (Umbriel in a window, own D-Bus session).
- **Style:** Noctalia themes itself from the wallpaper. Apps (GTK, Qt, LibreWolf) keep Adwaita's blue accent: a black accent was tried and disliked. Small changes, not many new files.
- **Comments: few and short.** Only where the code would otherwise get "fixed" back into a known bug, or a command/path you'd need (a one-liner, not a paragraph). No file headers restating what the file is, no narrating what a line does, no history (that's git). Longer explanations go in this file's Gotchas.
- **Nerd Font glyphs** (private-use, e.g. U+E0B6, U+F0176) get dropped silently by some edit tools: check with a codepoint dump.

## Map

**NixOS (the PCs)**
- `.config/nix/`, one file per topic (next to Nix's own untracked `github-token.conf`). `header.nix`: the entry point, only a list of the parts. Imported by the `/etc/nixos` stub `.config/scripts/configuration.nix` (sets `hostName`, `isLaptop`; on a fresh install it fetches the whole repo from GitHub).
  - `base.nix`: boot (Lanzaboote: Secure Boot keys made and enrolled by itself; TPM2 unlock of `cryptroot`, the LUKS name both machines must use: steps in `scripts/install.txt`), network, Tailscale, users, Nix, audio, power, nix-ld/AppImage/Flatpak. AppImages with their own updater (Nuvio, Longshot) live in `~/.local/share/appimages`: a path unit runs `appimage-menu.sh`, which makes their menu entries (icon from the AppImage) and drops them when the file goes.
  - `noctalia.nix` + `noctalia/`: the desktop. Noctalia and its greeter: their newest release tag, looked up at each rebuild; Umbriel and its portal have no releases: a flake on main, its lock updated by `rb -u`. Umbriel (compositor) + Noctalia (shell) + Noctalia Greeter (greetd), all built against the system nixpkgs. Umbriel's config: `.config/umbriel/config.toml` (includes the packaged one, then only my changes; reloads on save, `umbriel config validate`); its keybind helpers: `.config/umbriel/run.sh`. Noctalia does wallpaper, notifications, night light, idle/lock, clipboard, battery, brightness (ddcutil on the desktop), network/Bluetooth/audio panels, polkit. Noctalia's config: `.config/noctalia/config.toml` (shared by both machines: no per-machine includes, a missing include is fatal); Settings/IPC write `~/.local/state/noctalia/settings.toml` (untracked, wins over it), so move changes worth keeping into config.toml. `umbriel-nested`: Umbriel in a window.
  - `session.nix`: what the desktop runs on: keyring, portals (GTK next to Umbriel's), themes, cursor (the greeter reads it from here), default apps (folders: yazi in foot), fonts, the tools `wm/scripts` call.
  - `packages.nix`: apps and CLI tools. `dev.nix`: editors, language servers, containers, adb, KU Leuven's LaTeX.
  - `laptop.nix`, `desktop.nix` (drives, RGB, monitor, GPU), `gaming.nix` + `gaming/` (Steam, Protons, G920; scripts: `acmanager.sh` for Assetto Corsa links, `gamescope-sdl.sh`, `steam-rpc.py` for Discord), `optional.nix` (Unsloth Studio, Upscayl: each switched on by its own `true`).
  - Self-contained extras: `librewolf.nix` (bakes in `.config/librewolf/prefs.js` + `policies.json`), `webapps.nix` + `webapps/` (YouTube Music as an Electron app, see `webapp.js`; ads blocked by its `block` list and `ytmusic/preload.js`; Discord presence: `ytmusic/discord.js`).
- `.config/scripts/`: install scripts served by URL (`nix.b3n.me` → the NixOS stub; `arch.sh`/`void.sh` kept for future installs). Install steps: `install.txt`.
- `.local/bin/rb`: rebuild (`nixos-rebuild switch`, `nvd diff`, VSCodium extensions); `rb -u` upgrades. Power menu: *rebuild* = `cu` then `rb`, *update* = `cu` then `rb -u` and the rest; a failed `cu` doesn't stop them.

**Scripts** (`.config/wm/scripts/`): `power.sh`, `screenshot.sh` (ocr), `record.sh`, `idle.sh` (Noctalia's sleep) and `darkmode.sh apply` (Noctalia's `theme_mode_changed` hook).

**Other**
- Shell: bash is the login shell and runs scripts; foot starts fish + starship. **Aliases only in `.bashrc`**: fish imports its `alias` lines (`f`, a function, is in both). `.bash_profile` loads `.bashrc` on TTY/SSH logins (login shells skip `.bashrc`; needed as its own file).
- `.local/bin/cu`: sync (dotfiles, then `~/Documents/sync`: a private repo with one commit only, wallpapers in `wp/active/`; both sides are compared with `refs/sync/base`, the last commit they agreed on). `copy`: stdin/files into the clipboard.
- VSCodium: `.config/VSCodium/User/settings.json`; extensions listed in `.config/VSCodium/extensions`, installed by `rb`.
- Git identity and GitHub login: `.config/git/config`.
- Themes: dconf `color-scheme` is the truth; Noctalia toggles it (Mod+Shift+T) and its `theme_mode_changed` hook runs `darkmode.sh apply` for the rest (GTK3 theme, icons, qt6ct, open foot windows). GTK3 dark = `.local/share/themes/Mono-dark` (imports `../../adw-gtk3-dark`: a link made at login; never tracked), GTK4 = `.config/gtk-4.0/gtk.css`, Qt = qt6ct palettes in `.config/qt6ct/colors/` (`qt6ct.conf` is written by `darkmode.sh`, untracked).

## Gotchas (don't re-investigate)

- **Umbriel's cursor** must match dconf's (`session.nix` `cursorTheme`/`cursorSize`, which writes Umbriel's `[input.cursor]` to `share/umbriel/cursor.toml`, an optional include): its default is 24 and apps then draw a different one. `umbriel windows --json`: `active` is the window with keyboard focus, `focused` only the one focused on its workspace. Apps can't focus themselves on Wayland (Electron's `win.focus()` does nothing): focus through `umbriel msg window-focus` (`run.sh`). Umbriel/Noctalia are young: config keys can change on `nix flake update`. Umbriel suspends windows on hidden workspaces (no frame callbacks): gamescope then stalls the game (CS2 lost its game sounds in the background), fixed with a `background_render` rule.
- **LibreWolf** quits with its last window.
- `~/.local/bin` is in the session's PATH (`environment.localBinInPath`, from `/etc/profile`, which greetd sources): scripts call `rb`/`cu` by name.
- Tried and disliked: dimming unfocused windows, Qt's `gtk3` platform theme (old greys), foot `include=` of a state file (errors when missing), `GTK_THEME` (pins one theme), zathura (Evince everywhere).
- Tailscale needs `services.resolved`, or it takes over all DNS. `--accept-routes` once per machine: Linux ignores the homelab's subnets without it.
- Noctalia idle (shared by both machines): lock 3 min (5 s fade, moving cancels), screen off 3m10s (2 min after a manual lock), sleep at 5 min, which `idle.sh nap` stretches to 15 on the desktop and holds off while audio plays (its PID file lets `resume_command` cancel it).
- Umbriel binds replacing packaged ones: Mod alone (launcher, now `spawn true`: there's no unbind), Mod+Escape (lock; quit is Mod+Shift+M), Mod+M / Mod+Ctrl+F swapped. Floating windows get `blur_optimized = false` (the packaged blur shows only the wallpaper). foot: full-width column. yazi-side, chat, music and Steam: half-width columns, full width while alone.
- LibreWolf colours: Pywalfox (installed by policy) with Noctalia as its native host: the manifest comes from `librewolf.nix` (Noctalia's own installer and community template write `~/.mozilla`), the palette from the `pywalfox` user template. Policies: the plain DuckDuckGo with suggestions (LibreWolf's is noai.duckduckgo.com, without suggestions). Pref changes made in Settings before win over `defaultPref`, hence the few `pref()`. The toolbar is a `defaultPref` of `browser.uiCustomization.state` (extension buttons by widget id): a profile with its own saved layout keeps it until Customize → Restore Defaults and a restart (Restore Defaults clears the saved layout but draws Firefox's stock one; this pref is read only at startup). The new tab background is the current wallpaper: Noctalia's `wallpaper_changed` hook links it at `~/.cache/noctalia/wallpaper`, `prefs.js` checks that link every 10 s (a user stylesheet; nothing until the first wallpaper change). LibreWolf's own cfg sandboxes autoconfig (`Components` undefined, and the error stops every line after it): `librewolf.nix` turns it off in `autoconfig.js`, the only place read early enough. Autoconfig has no `btoa` unless imported; test changes headless with Marionette (`MOZ_REMOTE_ALLOW_SYSTEM_ACCESS=1`), `--screenshot` hangs on about:newtab.
- YouTube Music keeps Electron's own user agent: Google then serves its embedded-browser sign-in (`WebLiteSignIn`); a Chrome one gets the full flow, which rejects Electron as "may not be secure".
- Noctalia Greeter comes from the flake: nixpkgs' 1.3.1 can't sync the look (needs 1.5+).
- **rb speed:** whatever isn't on cache.nixos.org gets built on every nixpkgs update. Avoid overrides of big packages (`papirusGrey` links instead of rebuilding Papirus). Already avoided: fish's generated completions, the man page index, the NixOS manual. Nothing outside nixpkgs is pinned (no rev or hash): new versions arrive with `rb -u`, rollback is the boot menu. Still built locally: Umbriel (each `rb -u` that finds commits), Noctalia/its greeter/Yapfast/Lanzaboote's tool (each release), the TeX Live set, unfree repackaging (Steam, Claude), Unsloth Studio when switched on in `optional.nix` (FHS wrap of its .deb).
- `cu`'s sync repo: each sync is a new root commit, so a plain fetch gets every file again (the server only skips files under commits that are parents of what it sends, or covered by its bitmaps, and the old commit is unreachable after the force-push). `fetch --depth=1` makes the server skip the files of every commit the client has (`--objects-edge-aggressive`). This works while GitHub still keeps the old, unreachable commit. Partial clone (`blob:none`) was tried: it breaks the bitmap repack the push needs.
- Steam games run in a sandbox with a private `/tmp`: nothing outside can talk to a running Wine app.
- Longshot's FSR 4: `~/.local/share/fsr4/amd_fidelityfx_upscaler_vk.so` (AMD ships none for Linux), built from github.com/Astyyyyy/fsr4-vk and AMD's FidelityFX SDK v2.3.0 DLL (`VERSION` next to it). Rebuild in a nix-shell with `vulkan-loader vulkan-headers`, `-static-libstdc++ -static-libgcc -Wl,--exclude-libs,ALL` and a version script exporting only `ffx*` (else its libstdc++ symbols leak into Mesa: segfault in `codecvt` when gameplay starts), `zstandard` in the Python, then `patchelf --remove-rpath`: else it points into store paths GC deletes.
- Discord is Yapfast (its latest release, looked up at each rebuild in `packages.nix`; Vesktop is no longer installed on the PCs: if it comes back, don't run both, apps take the first `discord-ipc` socket that answers). Native Linux games get Rich Presence from `steam-rpc.py` (Steam's log + the IPC socket); Yapfast and arRPC find Proton games themselves. Discord's game list for it still comes from Vesktop's arRPC (`gaming.nix`), read from the package at build time: Vesktop needn't be installed.
- CS2 (4:3 stretched) runs in `gamescope-sdl` (`gaming.nix`): gamescope's default Wayland backend never pastes the desktop clipboard in, and slowed CS2 to ~120 fps / 50 ms with coloured noise lines after ~25 minutes. Its SDL backend breaks under Steam's `LD_LIBRARY_PATH` (the runtime's libSDL2) and `LD_PRELOAD`, and with `gamemoderun` in front of gamescope: the wrapper strips both for gamescope only, and gamemoderun goes after `--`.
- Assetto Corsa: Valve's Proton 9.0 from Steam (Wine 10+ blocks CSP's patching; GE-Proton9-20 crashed on NoHesi's server videos: its DXVK can't open shared textures), launch options `STEAM_COMPAT_LAUNCHER_SERVICE=proton WINEDLLOVERRIDES="dwrite=n,b;tabtip.exe=d" %command%` (Proton's tabtip, the Deck keyboard helper, turns on UI Automation, and CM's WPF tables then crash) (no gamescope; the launcher service is how `acmanager://` links reach an open Content Manager, see `gaming.nix`), its prefix's `Steam/config/loginusers.vdf` symlinks to Steam's, hidden CSP caches off in the prefix's `Documents/Assetto Corsa/cfg/extension/general.ini`. The prefix was made by a Wine 10 Proton: its leftover `winedmo.dll` crashed AC when NoHesi's server scripts opened media (moved to `compatdata/244210/winedmo-fix-backup-2026-10-30`, `winegstreamer.dll` re-registered with `wine64 regsvr32`); if media still breaks, recreate the prefix under GE-Proton9-20. Crash traces: `PROTON_LOG=1 PROTON_LOG_DIR=/home/ben/.cache` in the launch options.

## New machine

```bash
git clone --bare https://github.com/Bueezi/dotfiles.git ~/.dotfiles
alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
config config --local status.showUntrackedFiles no
config checkout   # if files already exist: move them aside first
```
Then copy `.config/scripts/configuration.nix` to `/etc/nixos/`, set `hostName` / `isLaptop`, rebuild, and run `cu` once (clones `~/Documents/sync`). Flatpaks by hand: `flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`, then `flatpak install --user flathub org.vinegarhq.Sober` (Roblox).
