#!/data/data/com.termux/files/usr/bin/bash
# Tablet (Honor MagicPad 4, Termux) setup and "rebuild": like .configuration.nix on NixOS, the lists
# below are what's installed. `rb` (this): installs what's missing and removes packages that aren't
# listed (apt shows the list and asks first), nothing gets updated. `rb -u` (the power menu's
# update) also updates everything: pkg, npm, Go, i3status-rs, TeX Live, the proot Debian, the
# Electron apps. Like rb / rb -u on NixOS. The very first run upgrades too.
# After the dotfiles, each part runs on its own: a failed one doesn't stop the others, and the failed
# ones are named at the end, with how long each part took. Everything also goes to $PREFIX/tmp/rb.log.
# Fresh tablet (Termux + Termux:X11 from F-Droid or GitHub, not the Play Store):
#   curl -L https://raw.githubusercontent.com/Bueezi/dotfiles/main/.config/scripts/termux.sh | bash
# That fetches the dotfiles first, then runs this file from them.
set -eo pipefail
[ -n "$TERMUX_VERSION" ] || { echo "Only for Termux" >&2; exit 1; }
say() { printf '\n==> %s\n' "$*"; }
self=~/.config/scripts/termux.sh
# Empty on a fresh tablet (no dotfiles yet): `|| true`, or set -e ended the script right here
self_before=$(md5sum 2>/dev/null < "$self" || true)
config() { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }

# The log: through `script`, so the terminal keeps its colours and apt its questions (a pipe to tee
# turns both off). Only when run from a terminal; the piped first install logs once it re-runs itself
log=$PREFIX/tmp/rb.log
if [ -z "$RB_LOG" ] && [ -t 0 ] && [ -t 1 ] && [ "${BASH_SOURCE[0]}" = "$self" ] && command -v script >/dev/null; then
    export RB_LOG=$log
    # SHELL: script runs the command with it, and Termux's is fish
    exec env SHELL="$BASH" script -qefc "$(printf '%q ' bash "$self" "$@")" "$log"
fi
# Android kills long builds (i3status-rs, TeX Live) when the screen goes off without a wake lock
termux-wake-lock 2>/dev/null || true
trap 'termux-wake-unlock 2>/dev/null' EXIT

# ── Packages (the "systemPackages" of the tablet) ───
PACKAGES=(
    x11-repo tur-repo
    # Desktop: X server, i3 (+ i3bar), compositor, notifications, launcher, terminal, wallpaper,
    # screenshots, clipboard tools, theme switching for GTK on X11 (xsettingsd), keyboard remaps
    termux-x11-nightly i3 dbus picom dunst libnotify rofi alacritty feh scrot xclip xdotool xsettingsd xorg-xrdb
    xorg-xkbcomp
    pulseaudio pavucontrol
    # GPU: Zink on Turnip (Adreno) for native apps, VirGL for the proot container. Termux's own mesa
    # (current, its Zink has kopper: real swapchains), not TUR's mesa-zink (Mesa 22.0 from 2022)
    mesa mesa-vulkan-icd-freedreno virglrenderer-android mesa-demos
    # Apps
    librewolf chromium mpv-x qbittorrent libreoffice zed code-oss
    # Electron: the web apps (~/.config/nixos/webapps), Vesktop and Claude, natively (no proot)
    electron42
    thunar thunar-archive-plugin gvfs tumbler file-roller eog evince
    # Look: icons, Qt palettes (qt6ct), dconf (dark mode's source of truth), fonts
    papirus-icon-theme adwaita-icon-theme qt6ct dconf fontconfig-utils
    ttf-dejavu ttf-jetbrains-mono-nerd ttf-iosevka-nerd
    # Shell and CLI
    fish starship helix helix-grammars git gh openssh wget curl less htop fastfetch cowsay jq ffmpeg zip unzip 7zip
    cava cmatrix pipes.sh freerdp manpages mandoc tesseract chafa fzf termux-api proot-distro
    # Development (KU Leuven list: TeX Live below, ddd in the proot container)
    clang make pkg-config binutils python nodejs golang rust rust-src rust-analyzer sqlite gdb openssl shellcheck
    # Language servers Termux packages (the rest: npm and Go below): LaTeX, TOML, Markdown (.NET)
    texlab taplo marksman
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
     @tailwindcss/language-server bash-language-server intelephense yaml-language-server)
GO=(go.senan.xyz/cliphist@latest github.com/sqls-server/sqls@latest)

# TeX Live: KU Leuven's list (texlive-latex-base, -latex-recommended, -fonts-recommended,
# -fonts-extra, -latex-extra, -lang-european, latexmk), the same as the desktop's collections
TEX=(collection-latex collection-latexrecommended collection-latexextra collection-fontsrecommended
     collection-fontsextra collection-langeuropean latexmk)

# Proot Debian: what Termux can't do natively (ddd: KU Leuven's gdb front-end; btop: not packaged)
PROOT_DISTRO=debian
PROOT_PACKAGES=(ddd btop)

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
/.config/VSCodium/User/settings.json
/.config/VSCodium/extensions
/.config/fastfetch/
/.config/nixos/webapps/
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

# ── The rest: one step each ──
failed=() times=()
# step <name> <function>: the function in a subshell with set -e of its own, so an error ends only
# that step. (`( … ) || …` would turn set -e off inside it: bash ignores it left of || and &&)
step() {
    say "$1"
    local t=$SECONDS
    set +e; ( set -e; "$2" ); local rc=$?; set -e
    times+=("$1 $((SECONDS - t))s")
    [ "$rc" = 0 ] || { failed+=("$1"); echo "==> $1: failed, carrying on"; }
}

build=~/.cache/termux-build; mkdir -p "$build"
# -u (or --upgrade): update everything too. The first run always does (no record of an earlier one yet):
# Termux's bootstrap is older than the packages it's about to install
upgrade="" first=""
case "${1:-}" in -u|--upgrade) upgrade=1 ;; esac
[ -e "$build/last-upgrade" ] || upgrade=1 first=1
# unchanged <name> <text>: the slow checks (tlmgr, Code - OSS, gio, proot) skip themselves when what
# they depend on is the same as at their last successful run; `record <name> <text>` notes it.
# Never with -u, which checks everything
unchanged() { [ -z "$upgrade" ] && [ "$(cat "$build/$1.stamp" 2>/dev/null)" = "$(printf '%s' "$2" | md5sum)" ]; }
record() { printf '%s' "$2" | md5sum > "$build/$1.stamp"; }
installed_pkgs() { dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' | awk '$1 == "ii" { print $2 }' | sort -u; }
# Downloads go to a temporary name first: an interrupted or failed one (404) isn't left behind
# looking installed, and the next run tries again
get() { curl -fL -o "$2.part" "$1" && mv "$2.part" "$2"; }
# untar <url> <dir>: a .tar.xz's folders into <dir>, each only once it's complete
untar() {
    local tmp=$build/untar d
    rm -rf "$tmp" && mkdir -p "$tmp" "$2"
    curl -fL "$1" | tar -xJ -C "$tmp"
    for d in "$tmp"/*; do rm -rf "${2:?}/${d##*/}"; mv "$d" "$2/"; done
}
# clone_at <GitHub repo> <commit> <dir>: that exact commit, like the PCs' pinned fetches (git checks
# that what it gets is that commit). A newer one: `git ls-remote https://github.com/<repo> HEAD`
clone_at() {
    rm -rf "$3" && git init -q "$3" && git -C "$3" fetch -q --depth 1 "https://github.com/$1" "$2" &&
        git -C "$3" checkout -q FETCH_HEAD
}
# latest_release <GitHub repo>: GitHub's answer about its latest release. Through gh when it's logged
# in (5000 questions an hour), else without a login (60 an hour)
latest_release() {
    gh api "repos/$1/releases/latest" 2>/dev/null || curl -s "https://api.github.com/repos/$1/releases/latest"
}

# ── Packages: install, then remove what isn't listed ──
packages() {
    local keep missing installed_keep extra
    # The X11 and TUR repositories first: apt plans a whole `pkg install` before installing anything,
    # so packages from a repository installed in the same command are "unable to locate"
    missing=$(comm -13 <(installed_pkgs) <(printf '%s\n' x11-repo tur-repo | sort))
    if [ -n "$missing" ] || [ -n "$upgrade" ]; then
        [ -z "$missing" ] || pkg install -y $missing
        # A repository mid-sync ("File has unexpected size") fails the update; apt keeps the previous
        # lists, so carry on instead of stopping
        pkg update -y || echo "Some package lists didn't update (a repository syncing?); using the previous ones"
    fi
    [ -z "$upgrade" ] || pkg upgrade -y -o Dpkg::Options::=--force-confold
    # Only the missing ones: `pkg install` of an installed package upgrades it, half an upgrade
    keep=$(printf '%s\n' "${PACKAGES[@]}" "${BASE[@]}" | sort -u)
    missing=$(comm -13 <(installed_pkgs) <(echo "$keep"))
    if [ -n "$missing" ]; then
        # Package lists from before a package got listed may not know it: update them, then again
        pkg install -y $missing || { pkg update -y || true; pkg install -y $missing; }
    fi
    installed_keep=$(comm -12 <(echo "$keep") <(installed_pkgs))
    apt-mark manual $installed_keep >/dev/null
    extra=$(comm -23 <(apt-mark showmanual | sort -u) <(echo "$keep"))
    [ -z "$extra" ] || apt-mark auto $extra >/dev/null
    # Asks before removing anything: check the list ("n" keeps them and carries on). Kept: marked manual
    # again, so a later autoremove doesn't take them without asking about this list
    apt autoremove --purge || { [ -z "$extra" ] || apt-mark manual $extra >/dev/null; echo "Nothing removed."; }
}
step Packages packages

npm_globals() {
    local npm_have p
    npm_have=$(npm ls -g --depth=0 --parseable 2>/dev/null | sed -n 's|.*/node_modules/||p')
    for p in "${NPM[@]}"; do grep -qxF "$p" <<<"$npm_have" || npm install -g "$p"; done
    # Only the listed ones: a plain `npm update -g` would replace pkg's own npm
    [ -z "$upgrade" ] || npm update -g "${NPM[@]}"
    for p in $npm_have; do
        case " ${NPM[*]} npm corepack " in *" $p "*) ;; *) npm uninstall -g "$p" ;; esac
    done
}
step npm npm_globals

go_programs() {
    export GOBIN=~/.local/bin
    local m f p have=
    # Unlisted ones go, like npm's. ~/.local/bin also has my scripts and the C builds below: only Go
    # programs count (`go version -m` names the package each was built from; the rest it can't read)
    for f in "$GOBIN"/*; do
        p=$(go version -m "$f" 2>/dev/null | awk '$1 == "path" { print $2 }') || true
        [ -n "$p" ] || continue
        case " ${GO[*]%@*} " in *" $p "*) have+=" $p" ;; *) echo "Removing ${f##*/} ($p): not in GO"; rm -f "$f" ;; esac
    done
    # The missing ones; with -u all (@latest: the newest version)
    for m in "${GO[@]}"; do
        [ -n "$upgrade" ] || case "$have " in *" ${m%@*} "*) continue ;; esac
        go install "$m"
    done
}
step Go go_programs

# ── Built from source (only when missing; i3status-rs also with -u, if there's a new version) ──
builds() {
    if [ ! -x ~/.local/bin/clipnotify ]; then
        say "clipnotify (X11 clipboard watcher for clipstore.sh)"
        clone_at cdown/clipnotify 25ba143c7da8ae0f196cb0db2797d30e6d04e15c "$build/clipnotify"
        make -C "$build/clipnotify"   # not `make && install`: set -e skips a failure left of &&
        install -m 755 "$build/clipnotify/clipnotify" ~/.local/bin/
    fi
    if [ ~/.config/termux/tray-spacer.c -nt ~/.local/bin/tray-spacer ]; then
        say "tray-spacer (keeps the bar's tray icons out of the round corner)"
        clang -O2 -o ~/.local/bin/tray-spacer ~/.config/termux/tray-spacer.c -lX11
    fi
    if [ ! -e "$PREFIX/lib/libsensors.so" ]; then
        # i3status-rs always links libsensors (its temperature block); Termux doesn't package it
        say "libsensors (lm-sensors)"
        clone_at lm-sensors/lm-sensors cb9a02a34035bfac3029cc1f4d981d099586a2cf "$build/lm-sensors"
        make -C "$build/lm-sensors" PREFIX="$PREFIX" ETCDIR="$PREFIX/etc" all-lib
        make -C "$build/lm-sensors" PREFIX="$PREFIX" ETCDIR="$PREFIX/etc" install-lib
    fi
    # Its sway/i3 connection (swayipc-async) needs async-pidfd, which refuses every target but
    # "linux": Android's kernel has pidfd, only Rust calls it "android". Build against a copy with
    # that one check widened (cargo keeps i3status-rs's pinned versions with it)
    local apd="$build/async-pidfd"
    if ! grep -qs 'target_os = "android"' "$apd/src/lib.rs"; then
        rm -rf "$apd" && mkdir -p "$apd"
        get https://static.crates.io/crates/async-pidfd/async-pidfd-0.1.5.crate "$build/async-pidfd.crate"
        # crates.io's checksum for it (from its index, what cargo itself checks)
        echo "958321a23896f573a3f1809437af5816f3bc90dd2d5ffe8b1cd5645f42230c17  $build/async-pidfd.crate" | sha256sum -c --quiet
        tar -xzf "$build/async-pidfd.crate" -C "$apd" --strip-components=1
        sed -i 's/#\[cfg(not(target_os = "linux"))\]/#[cfg(not(any(target_os = "linux", target_os = "android")))]/' "$apd/src/lib.rs"
        grep -q 'target_os = "android"' "$apd/src/lib.rs"
    fi
    i3rs() { cargo install --locked i3status-rs --config "patch.crates-io.async-pidfd.path=\"$apd\""; }
    if ! command -v i3status-rs >/dev/null; then
        say "i3status-rs (takes a while)"
        i3rs
    elif [ -n "$upgrade" ]; then
        # Cargo only builds when crates.io has a newer version. One that needs another async-pidfd
        # than the patched 0.1.5 fails to build: the installed one stays and the rest carries on
        say "i3status-rs: update"
        i3rs || echo "Couldn't build the new i3status-rs (another async-pidfd version?), keeping the installed one"
    fi
    # Its icon and theme files, from the newest version cargo has unpacked
    local i3rs_src
    i3rs_src=$(printf '%s\n' ~/.cargo/registry/src/*/i3status-rs-*/ | sort -V | tail -1)
    mkdir -p ~/.local/share/i3status-rust && cp -r "$i3rs_src"files/* ~/.local/share/i3status-rust/ 2>/dev/null || true
    # The same commit as the PCs (.configuration.nix, fetch's url): change both together.
    # fetch_rev: one up after changing the patches below (rebuilds once)
    local fetch_commit=e3087810e2a131ed4093440e783ac96a101ad806 fetch_rev=2
    if [ "$(cat "$build/fetch.rev" 2>/dev/null)" != "$fetch_commit $fetch_rev" ] || [ ! -x ~/.local/bin/fetch ]; then
        # Same as the desktop: logo in colour, grey usage percentages. Kernel without Android's long
        # suffix ("6.6.50-android15-8-g…-4k": 6.6.50), like fastfetch's config does
        say "fetch (areofyl)"
        clone_at areofyl/fetch "$fetch_commit" "$build/fetch"
        sed -i -E '/(pct|capacity) >=/ s/"(31|32|93)"/"38;5;248"/g' "$build/fetch/fetch.c"
        grep -q '"38;5;248"' "$build/fetch/fetch.c"
        sed -i 's|add_info("Kernel", "%s %s", u.sysname, u.release);|{ char *a = strstr(u.release, "-android"); if (a) *a = 0; } &|' "$build/fetch/fetch.c"
        grep -q 'strstr(u.release, "-android")' "$build/fetch/fetch.c"
        make -C "$build/fetch"
        install -m 755 "$build/fetch/fetch" ~/.local/bin/fetch
        echo "$fetch_commit $fetch_rev" > "$build/fetch.rev"
    fi
}
step "Source builds" builds

# ── Look: GTK theme, cursor, OCR languages ──
theming() {
    local themes=~/.local/share/themes icons=~/.local/share/icons url l t
    if [ ! -d "$themes/adw-gtk3-dark" ]; then
        # Mono-dark (tracked) imports ../../adw-gtk3-dark; NixOS links its system copy there instead
        say "adw-gtk3"
        # `|| true`: no answer (GitHub's question limit) only skips it, like below
        url=$(latest_release lassekongo83/adw-gtk3 | grep -o 'https://[^"]*\.tar\.xz' | head -1 || true)
        if [ -n "$url" ]; then untar "$url" "$themes"; else echo "No adw-gtk3 release found, next time"; fi
    fi
    if [ ! -d "$icons/Bibata-Modern-Classic" ]; then
        say "Bibata cursor"
        untar https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz "$icons"
        mkdir -p "$icons/default" && printf '[Icon Theme]\nInherits=Bibata-Modern-Classic\n' > "$icons/default/index.theme"
    fi
    for l in fra nld; do
        t="$PREFIX/share/tessdata/$l.traineddata"
        [ -f "$t" ] || get "https://github.com/tesseract-ocr/tessdata_fast/raw/main/$l.traineddata" "$t"
    done
    fc-cache >/dev/null   # not -f: only the font folders that changed
}
step "Look" theming

# ── Android integration ──
android() {
    # Storage access (Android's Download folder), asks once
    [ -d ~/storage ] || termux-setup-storage
    # Thunar's sidebar with the tablet's paths (the PCs' bookmarks file is left out of this checkout)
    # ~/Documents/shared = Android's Documents/shared: the same files for Android's apps and the desktop's
    # (the container sees it too). A folder of its own: git and Android's shared storage don't mix
    mkdir -p ~/Documents /storage/emulated/0/Documents/shared ||
        echo "No storage access yet: allow it, then rb again"
    ln -sfn /storage/emulated/0/Documents/shared ~/Documents/shared
    printf 'file://%s/Documents Documents\nfile://%s/Documents/shared Shared\nfile:///storage/emulated/0/Download Downloads\n' "$HOME" "$HOME" > ~/.config/gtk-3.0/bookmarks
    # The Termux app opens fish, without Termux's welcome text
    [ "$(readlink ~/.termux/shell 2>/dev/null)" = "$PREFIX/bin/fish" ] || chsh -s fish
    touch ~/.hushlogin
    # Termux:Widget buttons Start/Stop for the desktop (a folder named tasks = run in the background).
    # In ~/.shortcuts for its list widget, and as dynamic shortcuts (long-press the Termux:Widget icon,
    # drag one onto the home screen; Honor's launcher has no 1x1 shortcut widget) after pressing
    # "Create shortcuts" in the Termux:Widget app
    local dir
    for dir in ~/.shortcuts/tasks ~/.termux/widget/dynamic_shortcuts/tasks; do
        mkdir -p "$dir"
        printf '#!%s/bin/sh\nexec ~/.config/termux/bin/desktop\n' "$PREFIX" > "$dir/Start"
        # Stop: Termux too (else its "1 session" notification stays)
        printf '#!%s/bin/sh\nexec ~/.config/termux/bin/desktop exit\n' "$PREFIX" > "$dir/Stop"
        chmod 700 "$dir" "$dir"/*
    done
    chmod 700 ~/.shortcuts ~/.termux/widget ~/.termux/widget/dynamic_shortcuts
    # Their icons (▶ / ■): copies, Termux:Widget refuses links to outside ~/.shortcuts/icons. Shortcuts
    # already on the home screen keep their old icon: remove them, "Create shortcuts" again, re-add
    mkdir -p ~/.shortcuts/icons && chmod 700 ~/.shortcuts/icons
    install -m 600 ~/.config/termux/icons/Start.png ~/.config/termux/icons/Stop.png ~/.shortcuts/icons/

    # Termux's own settings (keys above the touch keyboard, colours): it only reads ~/.termux
    mkdir -p ~/.termux
    ln -sfn ~/.config/termux/termux.properties ~/.termux/termux.properties
    ln -sfn ~/.config/termux/colors.properties ~/.termux/colors.properties
    termux-reload-settings
}
step "Android integration" android

app_settings() {
    # LibreWolf: the same prefs and policies as the desktop (one source in .config/librewolf). The
    # overrides file sits next to the profiles (LibreWolf's XDG location)
    mkdir -p ~/.config/librewolf/librewolf "$PREFIX/lib/librewolf/distribution"
    ln -sfn ~/.config/librewolf/prefs.js ~/.config/librewolf/librewolf/librewolf.overrides.cfg
    ln -sfn ~/.config/librewolf/policies.json "$PREFIX/lib/librewolf/distribution/policies.json"

    # Code - OSS (`codium` here too): VSCodium's settings and extensions from the PCs
    mkdir -p ~/".config/Code - OSS/User"
    ln -sfn ~/.config/VSCodium/User/settings.json ~/".config/Code - OSS/User/settings.json"
    # The missing extensions, when the list changed (asking Code - OSS starts Electron: seconds)
    local list have
    list=$(grep -v '^\s*\(#\|$\)' ~/.config/VSCodium/extensions)
    unchanged code-extensions "$list" && return 0
    have=$(code-oss --list-extensions 2>/dev/null | tr 'A-Z' 'a-z')
    echo "$list" | while read -r e; do
        echo "$have" | grep -qx "$e" || code-oss --install-extension "$e" >/dev/null 2>&1 || echo "No $e"
    done
    record code-extensions "$list"
}
step "LibreWolf, Code - OSS" app_settings

# ── TeX Live (once; later `tlmgr install` only adds what's missing) ──
texlive() {
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
    # Only when a collection is missing: the font maps take minutes to rebuild. Asked only when TEX
    # changed (tlmgr takes seconds just to start)
    local missing
    if ! unchanged tex "${TEX[*]}"; then
        missing=$(comm -23 <(printf '%s\n' "${TEX[@]}" | sort) <(tlmgr info --only-installed --data name | sort))
        if [ -n "$missing" ]; then
            say "TeX Live: $(echo $missing)"
            tlmgr install $missing
            fmtutil-sys --quiet --byfmt pdflatex
            updmap-sys --quiet
            command -v texlinks >/dev/null && texlinks
        fi
        record tex "${TEX[*]}"
    fi
    # -u: updates (tlmgr itself first), then Termux's patches again on whatever got replaced (it
    # skips the ones already applied). A new TeX Live year can't be updated into, only reinstalled:
    # tlmgr says so, the rest carries on
    [ -n "$upgrade" ] || return 0
    say "TeX Live: update"
    if tlmgr update --self --all; then termux-patch-texlive >/dev/null; else echo "TeX Live not updated"; fi
}
step "TeX Live" texlive

# ── Proot Debian ──
proot_debian() {
    # Only when the list changed, or with -u (everything in proot is slow, even starting it)
    unchanged proot "$PROOT_DISTRO ${PROOT_PACKAGES[*]}" && return 0
    # Installed = it can log in (newer proot-distro versions keep containers elsewhere than installed-rootfs)
    proot-distro login "$PROOT_DISTRO" -- true 2>/dev/null || proot-distro install "$PROOT_DISTRO"
    local pk=${PROOT_PACKAGES[*]} cmd
    if [ -n "$upgrade" ]; then
        cmd="apt-get update -q && apt-get full-upgrade -y -o Dpkg::Options::=--force-confold && apt-get install -y $pk"
    else
        # A fresh container has no package lists yet: then update first
        cmd="apt-get install -y $pk || { apt-get update -q && apt-get install -y $pk; }"
    fi
    proot-distro login "$PROOT_DISTRO" -- sh -c "export DEBIAN_FRONTEND=noninteractive; $cmd"
    record proot "$PROOT_DISTRO ${PROOT_PACKAGES[*]}"
}
step "Proot $PROOT_DISTRO: ${PROOT_PACKAGES[*]}" proot_debian

# Desktop apps with only Linux (glibc) builds: Electron apps, so the app inside their arm64 .deb
# runs on Termux's own electron42 (launchers in .config/termux/bin: no proot, so the desktop's cursor,
# dark mode and tray). Its resources are unpacked into $PREFIX/opt/<name>, again with -u when
# GitHub has a newer release; Electron's files go next to them, like in the .deb: the app finds its own files
# (tray icon, translations) in the "resources" next to the program, and counts as installed only
# when the program isn't called "electron". So a copy named after the app (Android allows no hard
# links), renewed when electron42 updates.
# electron_app <name> <GitHub repo> <release file pattern> <app folder inside the .deb>
electron_app() {
    local url dir=$PREFIX/opt/$1 tmp=$PREFIX/tmp/$1 electron=$PREFIX/lib/electron42 f
    # Without -u GitHub is only asked when the app is missing
    if [ -n "$upgrade" ] || [ ! -e "$dir/release" ]; then
        # `|| true`: no match is an answer here, not an error (set -e ended the step)
        url=$(latest_release "$2" | grep -o "https://[^\"]*$3" | head -1 || true)
        [ -n "$url" ] || { echo "No $1 release found"; return; }
        if [ "$(cat "$dir/release" 2>/dev/null)" != "$url" ]; then
            say "$1: $(basename "$url")"
            curl -fL -o "$tmp.deb" "$url"
            rm -rf "$tmp" "$dir/resources"; mkdir -p "$dir"
            dpkg-deb -x "$tmp.deb" "$tmp"
            mv "$tmp/$4/resources" "$dir/"
            # The biggest icon, for the rofi entry
            find "$tmp/usr/share/icons" -name '*.png' -printf '%s %p\n' | sort -n | tail -1 | cut -d' ' -f2- |
                xargs -r -I{} cp {} "$dir/icon.png"
            echo "$url" > "$dir/release"
            rm -rf "$tmp" "$tmp.deb"
        fi
    fi
    for f in "$electron"/*; do
        case ${f##*/} in electron|resources|chrome_sandbox) ;; *) ln -sfn "$f" "$dir/" ;; esac
    done
    cp -pu "$electron/electron" "$dir/$1"   # -p keeps electron42's date: -u copies again when newer
}
electron_apps() {
    electron_app vesktop Vencord/Vesktop 'vesktop_[^"/]*_arm64\.deb' opt/Vesktop
    electron_app claude-desktop aaddrick/claude-desktop-debian 'claude-desktop_[^"/]*_arm64\.deb' usr/lib/claude-desktop
}
step "Vesktop, Claude Desktop" electron_apps

# rofi entries for the Electron apps. claude:// links: the browser hands the login back to Claude
# through its entry (%u = the link, passed on to the Claude already running)
apps=~/.local/share/applications
# entry <name> <command> <icon> <categories> [<MimeType>]
entry() {
    printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s\nIcon=%s\nCategories=%s\n' "$1" "$2" "$3" "$4" > "$apps/$1.desktop"
    [ -z "${5:-}" ] || echo "MimeType=$5" >> "$apps/$1.desktop"
}
# Default apps, like the PCs' (xdg.mime.defaultApplications), with GIO's own command (it writes
# ~/.config/mimeapps.list): for Thunar and xdg-open. Else whatever claims the type, like Chromium
mime() { local app=$1 t; shift; for t; do gio mime "$t" "$app" >/dev/null || echo "No $app for $t"; done; }
desktop_entries() {
    # Only when this part of the script changed (some 20 gio calls); -u always
    unchanged entries "$(declare -f desktop_entries entry mime)" && return 0
    mkdir -p "$apps"
    local bin=$HOME/.config/termux/bin c
    entry Vesktop "$bin/vesktop" discord "Network;InstantMessaging;"   # Papirus (its .deb has no png)
    entry Claude "$bin/claude-desktop %u" "$PREFIX/opt/claude-desktop/icon.png" "Utility;" "x-scheme-handler/claude;"
    entry Eclipse "$bin/eclipse" "$HOME/.config/nixos/webapps/eclipse/icon.png" "AudioVideo;Audio;Player;"
    # Termux's Chromium entry has unfilled placeholders (Exec=@@desktop_exec, Icon=@@desktop_icon): no
    # icon in rofi, no command. A copy here (same name: it replaces the system's) with both filled in
    c=$PREFIX/share/applications/chromium.desktop
    [ ! -f "$c" ] || sed -e "s|@@desktop_exec|$PREFIX/bin/chromium-browser|" -e 's/@@desktop_icon/chromium/' \
        -e '/@@/d' "$c" > "$apps/chromium.desktop"
    ! command -v update-desktop-database >/dev/null || update-desktop-database -q "$apps"

    mime librewolf.desktop x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml
    mime thunar.desktop inode/directory
    mime org.gnome.Evince.desktop application/pdf
    mime org.gnome.eog.desktop image/jpeg image/png image/gif image/bmp image/webp image/tiff
    mime mpv.desktop video/mp4 video/x-matroska video/webm audio/mpeg audio/flac audio/ogg
    record entries "$(declare -f desktop_entries entry mime)"
}
step "App entries, default apps" desktop_entries

say "Done"
echo "Took: $(printf '%s, ' "${times[@]}" | sed 's/, $//')"
# The first run: what's left to do by hand
[ -z "$first" ] || cat <<'EOF'

Once, on the Android side:
  - Developer options → "Disable child process restrictions" (else Android kills the desktop),
    and no battery optimisation for Termux and Termux:X11
  - Termux:X11 → Preferences: capture system shortcuts (Super for i3), clipboard sharing
  - Apps: Termux:API (battery, volume), Termux:Widget (desktop buttons), Tailscale (homelab)
  - Termux → "Display over other apps": lets the Start button bring Termux:X11 to the front
Then: `desktop` (or the Start button) starts X11 + i3 in the background.
EOF
if [ "${#failed[@]}" -gt 0 ]; then
    say "Failed: $(printf '%s, ' "${failed[@]}" | sed 's/, $//')"
    echo "The other steps ran. ${RB_LOG:+Details: $RB_LOG}"
    exit 1
fi
# A successful update is noted (the first run counts); a plain rb reminds after a week without one
if [ -n "$upgrade" ]; then
    touch "$build/last-upgrade"
else
    days=$(( ($(date +%s) - $(stat -c %Y "$build/last-upgrade")) / 86400 ))
    [ "$days" -lt 7 ] || echo "Last update $days days ago: rb -u (the power menu's update)"
fi
