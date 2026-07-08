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
  # Graphics
  # ────────────────────────────────────────────────
  # Covers both the 7430U's integrated Radeon graphics and the
  # RX 9070 XT — amdgpu picks up whichever is present automatically.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # ────────────────────────────────────────────────
  # CPU
  # ────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode = true;

  # ────────────────────────────────────────────────
  # Desktop Environment
  # ────────────────────────────────────────────────
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # ────────────────────────────────────────────────
  # Audio
  # ────────────────────────────────────────────────
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
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
  # Firmware updates (BIOS, peripherals) — useful on both machines
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
      # Shared: hard power button always shuts down.
      HandlePowerKey = "poweroff";
    }
    (lib.mkIf isLaptop {
      HandlePowerKeyLongPress = "poweroff";

      # lid close -> hibernate directly
      HandleLidSwitch = "hibernate";

      # AFK -> sleep after 5 min, then hibernate after 10 more
      # (see HibernateDelaySec below for the second stage)
      IdleAction = "suspend-then-hibernate";
      IdleActionSec = "5min";
    })
  ];

  # NOTE: hibernate (both lid-close and the idle suspend-then-hibernate path)
  # requires a resume target: either a swap partition >= RAM size with
  # `boot.resumeDevice`, or a swapfile with `resume_offset=` set via
  # boot.kernelParams. Verify this exists in hardware-configuration.nix /
  # your swapDevices config, or hibernate will silently fail to fire.
  # systemd.sleep.extraConfig = ''
  #   HibernateDelaySec=10min
  # '';

  # zram swap — mainly helps the laptop, harmless on desktop.
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

    # Distrobox
    distrobox
    distroshelf

    # DE extras
    cosmic-ext-tweaks
    cosmic-ext-calculator
    baobab
    eog
  ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";
}
