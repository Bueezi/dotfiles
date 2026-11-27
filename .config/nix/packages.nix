{ lib, pkgs, ... }:

let
  # main, locked in noctalia/flake.lock until `rb -u`
  lock = (lib.importJSON ./noctalia/flake.lock).nodes;
in
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
    (ungoogled-chromium.override { commandLineArgs = "--password-store=gnome-libsecret --close-window-with-last-tab=never"; })
    libreoffice
    # Latest release, not main: built from source, so every commit would be a long rebuild
    (builtins.getFlake "github:yapfast/yapfast/${(builtins.fromJSON (builtins.readFile
      (builtins.fetchurl "https://api.github.com/repos/yapfast/yapfast/releases/latest"))).tag_name}").packages.${stdenv.hostPlatform.system}.yapfast
    yazi glib tmux # glib: gio, for yazi's gvfs plugin
    claude-code
    (builtins.getFlake "github:aaddrick/claude-desktop-debian/${lock.claude-desktop.locked.rev}").packages.${stdenv.hostPlatform.system}.default
    ((callPackage "${builtins.fetchTarball {
      url = "https://github.com/areofyl/fetch/archive/${lock.fetch.locked.rev}.tar.gz"; sha256 = lock.fetch.locked.narHash;
    }}/nix/package.nix" { }).overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''sed -i -E '/(pct|capacity) >=/ s/"(31|32|93)"/"38;5;248"/g' fetch.c'';
    }))
  ];

  programs.chromium = {
    enable = true;
    extraOpts = {
      DefaultSearchProviderEnabled = true;
      DefaultSearchProviderName = "DuckDuckGo";
      DefaultSearchProviderKeyword = "duckduckgo.com";
      DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
      DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
    };
    # New profiles only: no policy exists for these. "shortcust" is Chromium's own spelling
    initialPrefs = {
      vertical_tabs.enabled = true;
      ntp.shortcust_visible = false;
    };
  };

  # Electron doesn't know "umbriel" and falls back to basic_text: Claude signed out at every start
  environment.sessionVariables.CLAUDE_PASSWORD_STORE = "gnome-libsecret";
}
