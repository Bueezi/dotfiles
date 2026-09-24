# Shared NixOS config for the laptop and the desktop.
# Imported by the stub in ~/.config/scripts/configuration.nix (which lives in /etc/nixos on each
# machine); per-machine settings (hostName, isLaptop) are set there.
{ config, lib, pkgs, isLaptop, ... }:

{
  # Optional extras from the dotfiles repo, skipped on a fresh install (no dotfiles yet)
  imports = builtins.filter builtins.pathExists [
    /home/ben/.config/nixos/librewolf.nix
  ];

  # ── Boot ────────────────────────────────────────────
  boot = {
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 3;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest; # RDNA4 needs a recent kernel
  };

  # Switch profile automatically on AC/battery
  services.udev.extraRules = lib.mkIf isLaptop ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced"
  '';

  # Don't power the Bluetooth radio until you need it
  hardware.bluetooth.powerOnBoot = !isLaptop;

  # Laptop's Realtek (rtw89) Wi-Fi card fix
  networking.networkmanager.wifi.powersave = lib.mkIf isLaptop false;

  boot.extraModprobeConfig = lib.mkIf isLaptop ''
    options rtw89_core disable_ps_mode=y
    options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y disable_clkreq=y
  '';

  # ── System basics ───────────────────────────────────
  networking.networkmanager.enable = true;

  services.printing.enable = true;
  services.avahi = { enable = true; nssmdns4 = true; openFirewall = true; };

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

  systemd.services.rgb-off = lib.mkIf (!isLaptop) {
    description = "Turn off RGB lighting";
    wantedBy = [ "multi-user.target" "suspend.target" ];
    after = [ "systemd-modules-load.service" "suspend.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.openrgb}/bin/openrgb --noautoconnect -m off";
    };
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
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Idle is handled by swayidle in the sway config.
  services.logind.settings.Login.HandleLidSwitch = lib.mkIf isLaptop "suspend-then-hibernate";

  # Laptop: how long to sleep before switching to hibernate
  systemd.sleep.settings.Sleep.HibernateDelaySec = lib.mkIf isLaptop "30min";
  boot.resumeDevice = lib.mkIf isLaptop "/dev/disk/by-uuid/8ac0d876-3d7b-485a-8948-4ccd737b8d5f";

  fileSystems."/mnt/nvme" = lib.mkIf (!isLaptop) {
    device = "/dev/disk/by-uuid/b2eb90c5-7585-4519-83e9-91808d894f17";   # from `blkid /dev/nvme0n1p3`
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=5s" "x-gvfs-show" "x-gvfs-name=nvme" ];
  };
  fileSystems."/mnt/hdd" = lib.mkIf (!isLaptop) {
    device = "/dev/disk/by-uuid/005AA8F65AA8EA1C";
    fsType = "ntfs3";   # the kernel's own NTFS driver, faster than ntfs-3g
    options = [
      "nofail" "x-systemd.device-timeout=5s"
      "uid=1000" "gid=100" "umask=022"   # NTFS has no Linux owners: make everything yours
      "x-gvfs-show" "x-gvfs-name=hdd"
    ];
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
      foot fuzzel i3status-rust mako libnotify swayr bzmenu 
      # clipboard picker (fzf + sixel image preview) and auto-paste
      fzf chafa wtype
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
    GTK_THEME = "Adwaita:dark";
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";    # Electron/Chromium on Wayland
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
  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Adwaita-dark";
        cursor-theme = "Adwaita";
        cursor-size = lib.gvariant.mkInt32 24;
      };
    }];
  };
  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Adwaita-dark
    gtk-application-prefer-dark-theme=1
    gtk-cursor-theme-name=Adwaita
    gtk-cursor-theme-size=24
  '';

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
    settings.experimental-features = [ "nix-command" "flakes" ];
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

  programs.appimage = {
    enable = true;
    binfmt = true;
    # Extra libraries AppImages expect in /usr/lib
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [ pkgs.mpv-unwrapped ]; # libmpv.so.2 for Nuvio's player
    };
  };
  services.flatpak.enable = true;

  # ── Packages ────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # CLI
    git gh gcc python3 less htop btop powertop fastfetch cowsay
    wl-clipboard zip unzip p7zip ffmpeg jq wl-mirror
    # Dev
    neovim helix vscode nodejs rustc cargo podman-compose sqlite dbeaver-bin
    distrobox distroshelf
    # LSP
    basedpyright
    # Apps
    librewolf ungoogled-chromium mpv vesktop qbittorrent
    libreoffice filezilla github-desktop bazaar gearlever
    # Claude Desktop (community build; updates to the latest version on rebuild)
    (builtins.getFlake "github:aaddrick/claude-desktop-debian").packages.${stdenv.hostPlatform.system}.default
  ]
  # ── Per-machine apps ────────────────────────────────
  # Packages installed on only one machine. (Apps that need a NixOS module, like
  # Steam, go in the "Gaming" section below instead.)
  ++ lib.optionals (!isLaptop) [ # desktop only
    upscayl               # AI image upscaler
    openrgb               # RGB control GUI/CLI (rgb-off below uses its own store path)
    rocmPackages.rocm-smi # GPU monitoring
    mangohud              # in-game FPS/temps overlay: `mangohud %command%` in Steam
    protontricks          # Windows fonts/libs into a game's Proton prefix (Content Manager)
    oversteer             # G920 settings: rotation, force feedback, pedal test
  ]
  ++ lib.optionals isLaptop [   # laptop only
  ];

  # ── Gaming (desktop only) ───────────────────────────
  programs.steam = lib.mkIf (!isLaptop) {
    enable = true;
    remotePlay.openFirewall = true;               # Steam Remote Play
    localNetworkGameTransfers.openFirewall = true; # copy games between PCs on the LAN
    extraCompatPackages = [ pkgs.proton-ge-bin ];  # Proton-GE, pick it per game in Properties > Compatibility
  };
  # Performance mode while a game runs: launch option `gamemoderun %command%`
  programs.gamemode.enable = !isLaptop;
  # Micro-compositor for games: HDR, frame limiting, upscaling (`gamescope --hdr-enabled -- %command%`)
  programs.gamescope = lib.mkIf (!isLaptop) {
    enable = true;
    capSysNice = true;
  };
  # GPU control (fan curves, power limit, undervolt): LACT app + its daemon
  services.lact.enable = !isLaptop;
  # Logitech G920: switch it out of Xbox mode so it shows up as a wheel
  hardware.usb-modeswitch.enable = !isLaptop;
  # Let Oversteer change wheel settings without root
  services.udev.packages = lib.mkIf (!isLaptop) [ pkgs.oversteer ];

  system.stateVersion = "26.05";
}
