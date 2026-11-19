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
    libreoffice gearlever
    (builtins.getFlake "github:yapfast/yapfast/03862f6394fad09b541d731181b819a3c9713d3f").packages.${stdenv.hostPlatform.system}.yapfast
    yazi
    (builtins.getFlake "github:aaddrick/claude-desktop-debian").packages.${stdenv.hostPlatform.system}.default
    ((callPackage "${builtins.fetchTarball {
      url = "https://github.com/areofyl/fetch/archive/e3087810e2a131ed4093440e783ac96a101ad806.tar.gz";
      sha256 = "sha256-hgoTIBD2pvZDJxefMz+g8ALs4lqsMHOPHH4wwiomsaA=";
    }}/nix/package.nix" { }).overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''sed -i -E '/(pct|capacity) >=/ s/"(31|32|93)"/"38;5;248"/g' fetch.c'';
    }))
  ];

  # Electron doesn't know "umbriel" and falls back to basic_text: Claude signed out at every start
  environment.sessionVariables.CLAUDE_PASSWORD_STORE = "gnome-libsecret";
}
