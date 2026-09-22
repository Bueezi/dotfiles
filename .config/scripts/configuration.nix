{ config, lib, pkgs, ... }:

let
  # Per-machine toggles — flip these when deploying to the other machine.
  hostName = "nixos"; # e.g. "laptop" / "desktop"
  isLaptop = true;    # true = 7430U laptop, false = 7500F + RX 9070 XT desktop
in
{
  imports = [ ./hardware-configuration.nix ];

  # ── Boot ────────────────────────────────────────────
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 3;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest; # RDNA4 needs a recent kernel
    kernelParams = lib.mkIf isLaptop [ "mem_sleep_default=deep" ];
  };

  # ── System basics ───────────────────────────────────
  networking = {
    inherit hostName;
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Brussels";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings.LC_TIME = "en_GB.UTF-8";

  users.users.ben = {
    isNormalUser = true;
    description = "Ben";
    extraGroups = [ "networkmanager" "wheel" "video" ];
  };

  zramSwap.enable = true;

  # ── Hardware ────────────────────────────────────────
  hardware = {
    graphics = { enable = true; enable32Bit = true; };
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    bluetooth.enable = true;
  };

  services.fwupd.enable = true;
  services.blueman.enable = true;

  services.hardware.openrgb = lib.mkIf (!isLaptop) {
    enable = true;
    motherboard = "amd";
  };

  # ── Audio ───────────────────────────────────────────
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa = { enable = true; support32Bit = true; };
    pulse.enable = true;
  };

  # ── Power ───────────────────────────────────────────
  powerManagement.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Idle is handled by swayidle in the sway config.
  services.logind.settings.Login = {
    HandlePowerKey = "poweroff";
  } // lib.optionalAttrs isLaptop {
    HandlePowerKeyLongPress = "poweroff";
    HandleLidSwitch = "hibernate";
  };

  # ── Desktop: Sway ───────────────────────────────────
  programs.sway = {
    enable = true;
    package = pkgs.swayfx; # lags behind sway; drop `hdr` lines in sway config if they error
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      export QT_QPA_PLATFORM="wayland;xcb"
      export PROTON_ENABLE_WAYLAND=1
      export PROTON_ENABLE_HDR=1
    '';
    extraPackages = with pkgs; [
      # session
      swaylock swayidle swaybg wdisplays kanshi wlsunset lxqt.lxqt-policykit
      # terminal, launcher, bar, notifications
      foot fuzzel i3status-rust mako libnotify
      # screenshots, recording, clipboard
      grim slurp wf-recorder cliphist
      # hardware controls (pulseaudio only for `pactl`)
      brightnessctl pulseaudio pavucontrol
      networkmanager_dmenu networkmanagerapplet
      # GUI utilities
      file-roller baobab eog adwaita-icon-theme
    ];
  };

  environment.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";    # Electron/Chromium on Wayland
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Login: greetd + tuigreet
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
  programs.dconf.enable = true;

  # Keyring unlocked at login via PAM
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # File manager + thumbnails, mounting, trash
  programs.thunar = {
    enable = true;
    plugins = [ pkgs.thunar-archive-plugin ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
  ];

  # ── Nix & containers ────────────────────────────────
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
    };
    optimise.automatic = true;
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  programs.appimage = { enable = true; binfmt = true; };
  services.flatpak.enable = true;
  programs.kdeconnect.enable = true;

  # ── Packages ────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # CLI
    git gh gcc less htop btop powertop fastfetch cowsay
    wl-clipboard zip unzip p7zip ffmpeg jq wl-mirror
    # Dev
    neovim helix vscode nodejs rustc cargo podman-compose
    distrobox distroshelf
    # Apps
    librewolf ungoogled-chromium mpv vesktop qbittorrent
    libreoffice filezilla github-desktop bazaar gearlever
  ] ++ lib.optionals (!isLaptop) [ rocmPackages.rocm-smi ];

  system.stateVersion = "26.05";
}
