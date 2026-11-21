{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bc gh gcc python3 htop btop powertop fastfetch cowsay
    wl-clipboard zip unzip p7zip ffmpeg jq wl-mirror
    imagemagick
    hyprpicker
    starship
    cava cmatrix pipes
    freerdp
    man-pages man-pages-posix
    nvd
    gdu
    file tree wget ripgrep fd xxd gnumake
    lsof psmisc dnsutils
    pciutils usbutils lm_sensors smartmontools nvme-cli
    exfatprogs
    librewolf mpv qbittorrent
    (ungoogled-chromium.override { commandLineArgs = "--password-store=gnome-libsecret"; })
    libreoffice
    # Latest release, not main: built from source, so every commit would be a long rebuild
    (builtins.getFlake "github:yapfast/yapfast/${(builtins.fromJSON (builtins.readFile
      (builtins.fetchurl "https://api.github.com/repos/yapfast/yapfast/releases/latest"))).tag_name}").packages.${stdenv.hostPlatform.system}.yapfast
    yazi zellij
    (builtins.getFlake "github:aaddrick/claude-desktop-debian").packages.${stdenv.hostPlatform.system}.default
    ((callPackage "${builtins.fetchTarball "https://github.com/areofyl/fetch/archive/main.tar.gz"}/nix/package.nix" { }).overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''sed -i -E '/(pct|capacity) >=/ s/"(31|32|93)"/"38;5;248"/g' fetch.c'';
    }))
  ];

  # Electron doesn't know "umbriel" and falls back to basic_text: Claude signed out at every start
  environment.sessionVariables.CLAUDE_PASSWORD_STORE = "gnome-libsecret";
}
