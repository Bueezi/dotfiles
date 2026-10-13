#!/data/data/com.termux/files/usr/bin/bash
# Tablet (Honor MagicPad 4, Termux) setup and "rebuild": like .configuration.nix on NixOS, the lists
# below are what's installed. Re-running installs what's missing and removes packages that aren't
# listed (apt shows the list and asks first). Power menu → update runs `pkg upgrade` and this.
# Fresh tablet (Termux + Termux:X11 from F-Droid or GitHub, not the Play Store):
#   curl -L https://raw.githubusercontent.com/Bueezi/dotfiles/main/.config/scripts/termux.sh | bash
# That fetches the dotfiles first, then runs this file from them.
set -eo pipefail
[ -n "$TERMUX_VERSION" ] || { echo "Only for Termux" >&2; exit 1; }
say() { printf '\n==> %s\n' "$*"; }
self=~/.config/scripts/termux.sh
self_before=$(cat "$self" 2>/dev/null | md5sum)
config() { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }

# ── Packages (the "systemPackages" of the tablet) ───
PACKAGES=(
    x11-repo tur-repo
    # Desktop: X server, i3 (+ i3bar), compositor, notifications, launcher, terminal, wallpaper,
    # screenshots, clipboard tools, theme switching for GTK on X11 (xsettingsd)
    termux-x11-nightly i3 dbus xcompmgr dunst libnotify rofi alacritty feh scrot xclip xdotool xsettingsd xorg-xrdb
    pulseaudio pavucontrol
    # GPU: Zink on Turnip (Adreno) for native apps, VirGL for the proot container
    mesa-zink mesa-vulkan-icd-freedreno virglrenderer-android mesa-demos
    # Apps
    librewolf chromium mpv-x qbittorrent libreoffice zed
    thunar thunar-archive-plugin gvfs tumbler file-roller eog
    # Look: icons, Qt palettes (qt6ct), dconf (dark mode's source of truth), fonts
    papirus-icon-theme adwaita-icon-theme qt6ct dconf fontconfig-utils
    ttf-dejavu ttf-jetbrains-mono-nerd ttf-iosevka-nerd
    # Shell and CLI
    fish starship helix git gh openssh wget curl less htop fastfetch cowsay jq ffmpeg zip unzip 7zip
    cava cmatrix pipes.sh freerdp manpages mandoc tesseract chafa fzf termux-api proot-distro
    # Development (KU Leuven list: TeX Live below, ddd in the proot container)
    clang make pkg-config binutils python nodejs golang rust rust-analyzer sqlite gdb openssl shellcheck
    texlive-installer
    # Only to build things below: libsensors (bison, flex), clipnotify (X11 headers)
    bison flex libx11 libxfixes
)
# Termux's own base: what a fresh install starts with (termux-packages' generate-bootstraps.sh), kept
# and installed even though no listed package needs it (`which` is in debianutils, for example)
BASE=(apt bash bzip2 command-not-found coreutils curl dash debianutils diffutils dos2unix dpkg ed
      findutils gawk grep gzip inetutils less lsof nano net-tools patch procps psmisc sed tar
      termux-am termux-core termux-exec termux-keyring termux-licenses termux-tools unzip util-linux
      xz-utils)

# npm (global) and Go: the language servers Termux doesn't package, and cliphist
NPM=(basedpyright vscode-langservers-extracted typescript typescript-language-server
     @tailwindcss/language-server bash-language-server intelephense)
GO=(go.senan.xyz/cliphist@latest github.com/sqls-server/sqls@latest)

# TeX Live: KU Leuven's list (texlive-latex-base, -latex-recommended, -fonts-recommended,
# -fonts-extra, -latex-extra, -lang-european, latexmk), the same as the desktop's collections
TEX=(collection-latex collection-latexrecommended collection-latexextra collection-fontsrecommended
     collection-fontsextra collection-langeuropean latexmk)

# Proot Debian: what Termux can't do natively (ddd: KU Leuven's gdb front-end)
PROOT_DISTRO=debian
PROOT_PACKAGES=(ddd)

# What the tablet checks out of the dotfiles (sparse checkout; NixOS and sway stay out)
SPARSE='/.bashrc
/.bash_profile
/.local/bin/
/.local/share/themes/Mono-dark/
/.config/CLAUDE.md
/.config/scripts/termux.sh
/.config/termux/
/.config/wm/
/.config/i3/
/.config/alacritty/
/.config/dunst/
/.config/rofi/
/.config/fish/
/.config/starship.toml
/.config/helix/
/.config/git/
/.config/gtk-3.0/
!/.config/gtk-3.0/bookmarks
/.config/gtk-4.0/
/.config/qt6ct/
/.config/librewolf/
/.config/xfce4/
/.config/zed/
/.config/fastfetch/
/.config/fetch/
/.config/cava/'

# ── Mirrors: the Europe group, before the first download. Without a group, pkg picks a random
# working mirror from all regions (Asia, North America…), not the fastest. Same as choosing
# "Europe" in termux-change-repo; pkg still switches to another European one if a mirror fails ──
europe="$PREFIX/etc/termux/mirrors/europe"
if [ "$(readlink "$PREFIX/etc/termux/chosen_mirrors")" != "$europe" ]; then
    say "Mirrors: Europe"
    rm -rf "$PREFIX/etc/termux/chosen_mirrors"
    ln -s "$europe" "$PREFIX/etc/termux/chosen_mirrors"
    pkg --check-mirror update
fi

# ── Dotfiles first (also what makes `curl … | bash` work) ──
if [ ! -d ~/.dotfiles ]; then
    say "Dotfiles"
    pkg install -y git
    # Partial clone: only the files the sparse checkout needs get downloaded
    git clone --bare --filter=blob:none https://github.com/Bueezi/dotfiles ~/.dotfiles
    config config status.showUntrackedFiles no
    config config core.sparseCheckout true
else
    # The latest dotfiles first (this script included). Local changes stay; if they'd conflict,
    # this is skipped and the local copy is used
    say "Dotfiles: update"
    config pull -q --ff-only origin main || echo "Couldn't update the dotfiles, using the local copy"
fi
printf '%s\n' "$SPARSE" > ~/.dotfiles/info/sparse-checkout
# Files the tablet keeps its own copy of at a left-out path (bookmarks) stay untracked here
config config sparse.expectFilesOutsideOfPatterns true
if ! config rev-parse -q --verify HEAD >/dev/null || [ ! -f ~/.config/scripts/termux.sh ]; then
    # Files that already exist (e.g. a default ~/.bashrc) go aside instead of blocking the checkout
    mkdir -p ~/.config-backup
    { config checkout 2>&1 || true; } | awk '/^\t/ { print $1 }' | while read -r f; do
        mkdir -p ~/.config-backup/"$(dirname "$f")" && mv ~/"$f" ~/.config-backup/"$f"
    done
    config checkout
fi
config read-tree -mu HEAD   # apply the sparse list (new paths appear, removed ones go)
# Piped in (`curl … | bash`): run the checked-out copy, with the keyboard for the questions below.
# Same when the update above changed this script: carry on with the new version
if [ ! -t 0 ] && [ "${BASH_SOURCE[0]}" != "$self" ]; then
    exec bash "$self" "$@" < /dev/tty
elif [ "$(md5sum < "$self")" != "$self_before" ]; then
    exec bash "$self" "$@"
fi

# ── Packages: install, then remove what isn't listed ──
say "Packages"
# The X11 and TUR repositories first: apt plans a whole `pkg install` before installing anything,
# so packages from a repository installed in the same command are "unable to locate"
pkg install -y x11-repo tur-repo
# A repository mid-sync ("File has unexpected size") fails the update; apt keeps the previous lists,
# so carry on instead of stopping
pkg update -y || echo "Some package lists didn't update (a repository syncing?); using the previous ones"
pkg upgrade -y -o Dpkg::Options::=--force-confold
pkg install -y "${PACKAGES[@]}" "${BASE[@]}"
keep=$(printf '%s\n' "${PACKAGES[@]}" "${BASE[@]}" | sort -u)
installed_keep=$(comm -12 <(echo "$keep") <(dpkg-query -W -f='${Package}\n' | sort -u))
apt-mark manual $installed_keep >/dev/null
extra=$(comm -23 <(apt-mark showmanual | sort -u) <(echo "$keep"))
[ -n "$extra" ] && apt-mark auto $extra >/dev/null
# Asks before removing anything: check the list ("n" keeps them and carries on)
apt autoremove --purge || echo "Nothing removed."

say "npm"
npm_have=$(npm ls -g --depth=0 --parseable 2>/dev/null | sed -n 's|.*/node_modules/||p')
for p in "${NPM[@]}"; do grep -qxF "$p" <<<"$npm_have" || npm install -g "$p"; done
for p in $npm_have; do
    case " ${NPM[*]} npm corepack " in *" $p "*) ;; *) npm uninstall -g "$p" ;; esac
done

say "Go"
export GOBIN=~/.local/bin
for m in "${GO[@]}"; do
    b=${m%@*}; b=${b##*/}
    [ -x "$GOBIN/$b" ] || go install "$m"
done

# ── Built from source (only when missing) ──
build=~/.cache/termux-build; mkdir -p "$build"
if [ ! -x ~/.local/bin/clipnotify ]; then
    say "clipnotify (X11 clipboard watcher for clipstore.sh)"
    rm -rf "$build/clipnotify" && git clone -q --depth 1 https://github.com/cdown/clipnotify "$build/clipnotify"
    make -C "$build/clipnotify" && install -m 755 "$build/clipnotify/clipnotify" ~/.local/bin/
fi
if [ ! -e "$PREFIX/lib/libsensors.so" ]; then
    # i3status-rs always links libsensors (its temperature block); Termux doesn't package it
    say "libsensors (lm-sensors)"
    rm -rf "$build/lm-sensors" && git clone -q --depth 1 https://github.com/lm-sensors/lm-sensors "$build/lm-sensors"
    make -C "$build/lm-sensors" PREFIX="$PREFIX" ETCDIR="$PREFIX/etc" all-lib
    make -C "$build/lm-sensors" PREFIX="$PREFIX" ETCDIR="$PREFIX/etc" install-lib
fi
if ! command -v i3status-rs >/dev/null; then
    say "i3status-rs (takes a while)"
    # Its sway/i3 connection (swayipc-async) needs async-pidfd, which refuses every target but
    # "linux": Android's kernel has pidfd, only Rust calls it "android". Build against a copy with
    # that one check widened (cargo keeps i3status-rs's pinned versions with it)
    apd="$build/async-pidfd"
    rm -rf "$apd" && mkdir -p "$apd"
    curl -sL https://static.crates.io/crates/async-pidfd/async-pidfd-0.1.5.crate | tar -xz -C "$apd" --strip-components=1
    sed -i 's/#\[cfg(not(target_os = "linux"))\]/#[cfg(not(any(target_os = "linux", target_os = "android")))]/' "$apd/src/lib.rs"
    grep -q 'target_os = "android"' "$apd/src/lib.rs"
    cargo install --locked i3status-rs --config "patch.crates-io.async-pidfd.path=\"$apd\""
    mkdir -p ~/.local/share/i3status-rust && cp -r ~/.cargo/registry/src/*/i3status-rs-*/files/* ~/.local/share/i3status-rust/ 2>/dev/null || true
fi
# (Also replaces the old black-and-white wrapper script around fetch-bin. Not a search for
# "--no-color": the program itself contains that option, so it rebuilt on every run)
if [ ! -x ~/.local/bin/fetch ] || grep -q fetch-bin ~/.local/bin/fetch; then
    # Same as the desktop: logo in colour, grey usage percentages
    say "fetch (areofyl)"
    rm -rf "$build/fetch" && git clone -q --depth 1 https://github.com/areofyl/fetch "$build/fetch"
    sed -i -E '/(pct|capacity) >=/ s/"(31|32|93)"/"38;5;248"/g' "$build/fetch/fetch.c"
    make -C "$build/fetch" && install -m 755 "$build/fetch/fetch" ~/.local/bin/fetch
    rm -f ~/.local/bin/fetch-bin
fi

# ── Look: GTK theme, cursor, OCR languages ──
themes=~/.local/share/themes icons=~/.local/share/icons
if [ ! -d "$themes/adw-gtk3-dark" ]; then
    # Mono-dark (tracked) imports ../../adw-gtk3-dark; NixOS links its system copy there instead
    say "adw-gtk3"
    url=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | grep -o 'https://[^"]*\.tar\.xz' | head -1)
    mkdir -p "$themes" && curl -L "$url" | tar -xJ -C "$themes"
fi
if [ ! -d "$icons/Bibata-Modern-Classic" ]; then
    say "Bibata cursor"
    mkdir -p "$icons" && curl -L https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz | tar -xJ -C "$icons"
    mkdir -p "$icons/default" && printf '[Icon Theme]\nInherits=Bibata-Modern-Classic\n' > "$icons/default/index.theme"
fi
for l in fra nld; do
    t="$PREFIX/share/tessdata/$l.traineddata"
    [ -f "$t" ] || curl -L -o "$t" "https://github.com/tesseract-ocr/tessdata_fast/raw/main/$l.traineddata"
done
fc-cache -f >/dev/null

# ── Android integration ──
# Storage access (Android's Download folder), asks once
[ -d ~/storage ] || termux-setup-storage
# Thunar's sidebar with the tablet's paths (the PCs' bookmarks file is left out of this checkout)
printf 'file://%s/Documents Documents\nfile:///storage/emulated/0/Download Downloads\n' "$HOME" > ~/.config/gtk-3.0/bookmarks
# The Termux app opens fish, without Termux's welcome text
[ "$(readlink ~/.termux/shell 2>/dev/null)" = "$PREFIX/bin/fish" ] || chsh -s fish
touch ~/.hushlogin
# Termux:Widget buttons (a folder named tasks = run in the background): desktop start/stop. In
# ~/.shortcuts for its list widget, and as dynamic shortcuts (long-press the Termux:Widget icon,
# drag one onto the home screen; Honor's launcher has no 1x1 shortcut widget) after pressing
# "Create shortcuts" in the Termux:Widget app
for dir in ~/.shortcuts/tasks ~/.termux/widget/dynamic_shortcuts/tasks; do
    mkdir -p "$dir"
    printf '#!%s/bin/sh\nexec ~/.config/termux/bin/d\n' "$PREFIX" > "$dir/Desktop"
    printf '#!%s/bin/sh\nexec ~/.config/termux/bin/d stop\n' "$PREFIX" > "$dir/Desktop stop"
    chmod 700 "$dir" "$dir"/*
done
chmod 700 ~/.shortcuts ~/.termux/widget ~/.termux/widget/dynamic_shortcuts

# ── Termux's own settings (keys above the touch keyboard, colours): it only reads ~/.termux ──
mkdir -p ~/.termux
ln -sfn ~/.config/termux/termux.properties ~/.termux/termux.properties
ln -sfn ~/.config/termux/colors.properties ~/.termux/colors.properties
termux-reload-settings

# ── LibreWolf: the same prefs and policies as the desktop (one source in .config/librewolf) ──
# The overrides file sits next to the profiles (LibreWolf's XDG location; not the old ~/.librewolf)
mkdir -p ~/.config/librewolf/librewolf "$PREFIX/lib/librewolf/distribution"
ln -sfn ~/.config/librewolf/prefs.js ~/.config/librewolf/librewolf/librewolf.overrides.cfg
rm -rf ~/.librewolf
ln -sfn ~/.config/librewolf/policies.json "$PREFIX/lib/librewolf/distribution/policies.json"

# ── TeX Live (once; later `tlmgr install` only adds what's missing) ──
# Installed = the package database install-tl writes (texlive-bin already ships tlmgr before that)
if ! compgen -G "$PREFIX/share/texlive/*/tlpkg/texlive.tlpdb" >/dev/null; then
    say "TeX Live: scheme-basic, then KU Leuven's collections (several GB)"
    # Termux's termux-install-tl, without its questions and with scheme-basic instead of scheme-full
    sed 's/^selected_scheme .*/selected_scheme scheme-basic/' "$PREFIX/opt/texlive/termux.profile" > "$build/texlive.profile"
    source "$PREFIX/etc/profile.d/texlive.sh"
    "$PREFIX/opt/texlive/install-tl/install-tl" -custom-bin "$PREFIX/bin/texlive" -profile "$build/texlive.profile"
    termux-patch-texlive
fi
source "$PREFIX/etc/profile.d/texlive.sh"
# Only when a collection is missing: tlmgr goes online, and the font maps take minutes to rebuild
missing=$(comm -23 <(printf '%s\n' "${TEX[@]}" | sort) <(tlmgr info --only-installed --data name | sort))
if [ -n "$missing" ]; then
    say "TeX Live: $(echo $missing)"
    tlmgr install $missing
    fmtutil-sys --quiet --byfmt pdflatex
    updmap-sys --quiet
    command -v texlinks >/dev/null && texlinks
fi

# ── Proot Debian ──
say "Proot $PROOT_DISTRO: ${PROOT_PACKAGES[*]}"
# Installed = it can log in (newer proot-distro versions keep containers elsewhere than installed-rootfs)
proot-distro login "$PROOT_DISTRO" -- true 2>/dev/null || proot-distro install "$PROOT_DISTRO"
proot-distro login "$PROOT_DISTRO" -- sh -c "apt-get update -q && apt-get install -y ${PROOT_PACKAGES[*]}"

say "Done"
cat <<'EOF'
Once, on the Android side:
  - Developer options → "Disable child process restrictions" (else Android kills the desktop),
    and no battery optimisation for Termux and Termux:X11
  - Termux:X11 → Preferences: capture system shortcuts (Super for i3), clipboard sharing
  - Apps: Termux:API (battery, volume), Termux:Widget (desktop buttons), Tailscale (homelab)
Then: `d` starts X11 + i3 (in the background).
EOF
