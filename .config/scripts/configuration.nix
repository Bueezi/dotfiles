{ config, lib, pkgs, ... }:
let
  # ────────────────────────────────────────────────
  # Per-machine toggles — flip these two when deploying
  # to the other machine, everything else adapts.
  # ────────────────────────────────────────────────
  hostName = "nixos"; # e.g. "laptop" / "desktop"
  isLaptop = true; # true = 7430U laptop, false = 7500F + RX 9070 XT desktop
    
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # ────────────────────────────────────────────────
  # Boot & Kernel
  # ────────────────────────────────────────────────
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.loader.systemd-boot.configurationLimit = 3;

  # RDNA4 (RX 9070 XT) needs a recent kernel; also fine on the laptop's iGPU.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Laptop-only: deeper sleep state for suspend.
  boot.kernelParams = lib.mkIf isLaptop [ "mem_sleep_default=deep" ];

  # ────────────────────────────────────────────────
  # Networking & Basics
  # ────────────────────────────────────────────────
  networking = {
    inherit hostName;
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Brussels";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_GB.UTF-8";
    };
  };

  # ────────────────────────────────────────────────
  # Desktop — Sway
  # ────────────────────────────────────────────────
  programs.sway = {
    enable = true;
    # Uncomment to use SwayFX (blur, rounded corners, shadows).
    # SwayFX can lag behind sway releases; if the `hdr` lines in your
    # sway config then error, remove them.
    package = swayfx;
    wrapperFeatures.gtk = true; # proper GTK app theming/env
    extraSessionCommands = ''
      export QT_QPA_PLATFORM="wayland;xcb"
      export PROTON_ENABLE_WAYLAND=1
      export PROTON_ENABLE_HDR=1
    '';
    extraPackages = with pkgs; [
      swaylock
      swayidle
      foot                  # $term
      fuzzel                # $menu, clipboard picker
      thunar                # $fm (also enabled via programs.thunar below)
      brightnessctl         # brightness keys
      grim                  # screenshots
      slurp                 # region select for grim
      mako                  # notifications
      libnotify             # notify-send (screenshot bind, battery script)
      swaybg                # `output * bg ...`
      cliphist              # clipboard history
      pulseaudio            # only for `pactl` (volume keys); PipeWire stays the server
      pavucontrol           # audio mixer GUI
      i3status-rust         # bar status_command
      networkmanager_dmenu  # $mod+Shift+n
      networkmanagerapplet
      lxqt.lxqt-policykit   # polkit auth prompts
      kanshi                # monitor profiles (handy for the laptop)
      adwaita-icon-theme
    ];
  };

  # Login screen: greetd + tuigreet launching sway
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
      user = "greeter";
    };
  };

  # Screen sharing, file pickers, Flatpak integration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "wlr" "gtk" ];
  };

  security.polkit.enable = true;

  # Keyring: unlocked automatically at login through PAM,
  # so the gnome-keyring exec line in the sway config isn't needed.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  programs.dconf.enable = true; # GTK settings storage

  # File manager + thumbnails / mounting / trash
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Bluetooth manager (blueman-manager is in your floating rules)
  services.blueman.enable = true;

  # OpenRGB for `exec openrgb -m off` (desktop only)
  services.hardware.openrgb = lib.mkIf (!isLaptop) {
    enable = true;
    motherboard = "amd";
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts            # "Noto Sans" used by sway and the bar
    noto-fonts-color-emoji
    font-awesome          # i3status-rust icons
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
  ];

  # ────────────────────────────────────────────────
  # Graphics
  # ────────────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  #hardware accel
  hardware.enableRedistributableFirmware = true;

  # ────────────────────────────────────────────────
  # CPU
  # ────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode = true;

  # ────────────────────────────────────────────────
  # Audio
  # ────────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ────────────────────────────────────────────────
  # Bluetooth
  # ────────────────────────────────────────────────
  hardware.bluetooth.enable = true;

  # ────────────────────────────────────────────────
  # Firmware updates
  # ────────────────────────────────────────────────
  services.fwupd.enable = true;

  # ────────────────────────────────────────────────
  # Power Management & Battery Saving
  # ────────────────────────────────────────────────
  powerManagement.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Idle handling is done by swayidle in the sway config.
  services.logind.settings.Login = lib.mkMerge [
    {
      HandlePowerKey = "poweroff";
    }
    (lib.mkIf isLaptop {
      HandlePowerKeyLongPress = "poweroff";
      HandleLidSwitch = "hibernate";
    })
  ];

  zramSwap.enable = true;

  # ────────────────────────────────────────────────
  # User
  # ────────────────────────────────────────────────
  users.users.ben = {
    isNormalUser = true;
    description = "Ben";
    extraGroups = [ "networkmanager" "wheel" "video" ];
  };

  # ────────────────────────────────────────────────
  # Nix Garbage Collection & Optimization
  # ────────────────────────────────────────────────
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
    };
    optimise.automatic = true;
  };

  # ────────────────────────────────────────────────
  # Podman
  # ────────────────────────────────────────────────
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # ────────────────────────────────────────────────
  # Packages
  # ────────────────────────────────────────────────
  environment.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";

    # Forces Electron and Chromium apps to use Wayland
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    #alacritty
    htop
    btop
    rocmPackages.rocm-smi
    clinfo # see if hardware accel on
    libva-utils
    fastfetch
    cowsay
    less
    wl-clipboard
    powertop
    git
    gh
    gcc
    zip
    unzip
    p7zip
    qbittorrent

    # Editors & dev
    neovim
    helix
    vscode
    nodejs
    podman-compose

    # Browsers
    librewolf
    ungoogled-chromium

    # Media
    ffmpeg
    mpv

    # Office & tools
    filezilla
    github-desktop
    # orca-slicer

    # Distrobox
    distrobox
    distroshelf

    # Useful extras
    baobab
    eog
  ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";
}
