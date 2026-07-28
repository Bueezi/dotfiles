{ config, lib, pkgs, ... }:

let
  # ────────────────────────────────────────────────
  # Per-machine toggles — flip these two when deploying
  # to the other machine, everything else adapts.
  # ────────────────────────────────────────────────
  hostName = "nixos";      # e.g. "laptop" / "desktop"
  isLaptop = true;         # true = 7430U laptop, false = 7500F + RX 9070 XT desktop
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
  # Desktop Environment — KDE Plasma 6
  # ────────────────────────────────────────────────

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = true;

  # X11 keyboard layout (still read by Plasma/SDDM even under Wayland)
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # ────────────────────────────────────────────────
  # Graphics
  # ────────────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

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

  services.logind.settings.Login = lib.mkMerge [
    {
      HandlePowerKey = "poweroff";
    }
    (lib.mkIf isLaptop {
      HandlePowerKeyLongPress = "poweroff";
      HandleLidSwitch = "hibernate";
      IdleAction = "suspend-then-hibernate";
      IdleActionSec = "5min";
    })
  ];

  zramSwap.enable = true;

  # ────────────────────────────────────────────────
  # User
  # ────────────────────────────────────────────────
  users.users.ben = {
    isNormalUser = true;
    description = "Ben";
    extraGroups = [ "networkmanager" "wheel" ];
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
  environment.systemPackages = with pkgs; [
    #alacritty
    htop
    btop
    fastfetch
    cowsay
    less
    wl-clipboard
    powertop
    git
    gcc
    zip
    unzip
    p7zip
    telegram-desktop

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
    stremio-linux-shell
    ffmpeg
    mpv

    # Office & tools
    filezilla
    github-desktop
    orca-slicer

    # Distrobox
    distrobox
    distroshelf

    # Base DE utilities
    kdePackages.filelight  # KDE equivalent of baobab (disk usage)
    kdePackages.gwenview   # KDE equivalent of eog (image viewer)
  ];

  # KDE apps live under a top-level attribute set; not everything needs `with pkgs`
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    #elisa      # example: drop the default music player if unwanted
    #khelpcenter
  ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";
}
