# Apps and command-line tools on both machines. Development: dev.nix; one machine only: desktop.nix,
# gaming.nix; the desktop's own tools: session.nix, noctalia.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # CLI
    bc git gh gcc python3 less htop btop powertop fastfetch cowsay
    wl-clipboard zip unzip p7zip ffmpeg jq wl-mirror
    imagemagick  # magick: convert/resize images
    hyprpicker   # colour picker: click a pixel, hex to stdout (-a: also to the clipboard)
    starship  # prompt, ~/.config/starship.toml
    cava cmatrix pipes  # music visualiser (~/.config/cava/config), eye candy
    freerdp   # RDP into Windows: sdl-freerdp /v:<ip> /u:<user> /dynamic-resolution
    man-pages man-pages-posix # man
    nvd   # rb: what each rebuild changed
    gdu   # disk usage, in the terminal: gdu <dir>
    # Basics a minimal NixOS leaves out: what a file is, folders as a tree, downloads, searching
    file tree wget ripgrep fd xxd gnumake
    # What's using it: open files/ports (lsof), killall/pstree/fuser (psmisc), DNS (dig, nslookup)
    lsof psmisc dnsutils
    # Hardware: lspci, lsusb, temperatures (sensors), drive health (smartctl, nvme smart-log)
    pciutils usbutils lm_sensors smartmontools nvme-cli
    exfatprogs   # mkfs.exfat: USB sticks and SD cards that Windows/macOS/phones read
    # Apps
    librewolf mpv qbittorrent
    # Its cookie key in the keyring, as for Claude below (only the launcher is rebuilt, not Chromium)
    (ungoogled-chromium.override { commandLineArgs = "--password-store=gnome-libsecret"; })
    libreoffice bazaar gearlever
    # Yapfast: native Discord client (Umbriel: Mod+Shift+D). Pinned to v0.3.0's commit; its flake has
    # its own lock, so it's compiled once per pin, not on every nixpkgs update
    (builtins.getFlake "github:yapfast/yapfast/03862f6394fad09b541d731181b819a3c9713d3f").packages.${stdenv.hostPlatform.system}.yapfast
    yazi   # terminal file manager, with its preview tools (Umbriel: Mod+E, Mod+Shift+E; folders from other apps: session.nix)
    # Claude Desktop (community build; updates to the latest version on rebuild)
    (builtins.getFlake "github:aaddrick/claude-desktop-debian").packages.${stdenv.hostPlatform.system}.default
    # fetch by areofyl: spinning 3D distro logo + system info (not in 26.05 yet; built with the
    # system nixpkgs). Pinned: newer = a newer rev + its hash (nix-prefetch-url --unpack <url>, then
    # nix hash convert --hash-algo sha256 <it>). Logo in colour, grey usage percentages.
    # The tablet builds the same commit (termux.sh, fetch_commit): change both together
    ((callPackage "${builtins.fetchTarball {
      url = "https://github.com/areofyl/fetch/archive/e3087810e2a131ed4093440e783ac96a101ad806.tar.gz";
      sha256 = "sha256-hgoTIBD2pvZDJxefMz+g8ALs4lqsMHOPHH4wwiomsaA=";
    }}/nix/package.nix" { }).overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''sed -i -E '/(pct|capacity) >=/ s/"(31|32|93)"/"38;5;248"/g' fetch.c'';
    }))
  ];

  # Claude Desktop's sign-in in the keyring: Electron picks its secret store from XDG_CURRENT_DESKTOP,
  # doesn't know "umbriel" and falls back to basic_text, where Claude won't keep its tokens (signed out
  # at every start). Its launcher passes this on as --password-store
  environment.sessionVariables.CLAUDE_PASSWORD_STORE = "gnome-libsecret";
}
