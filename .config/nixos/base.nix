# The system underneath: boot, network, users, Nix, audio, power, ways to run outside software
{ pkgs, ... }:

{
  # ── Boot ────────────────────────────────────────────
  boot = {
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 3;
      # No editing kernel options at the boot menu: anyone at the keyboard could boot init=/bin/sh as root
      systemd-boot.editor = false;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest; # RDNA4 needs a recent kernel
  };

  # ── System basics ───────────────────────────────────
  networking.networkmanager.enable = true;
  # Tailscale: reach the homelab from anywhere. Once per machine: `sudo tailscale up --accept-routes`
  # (Linux ignores the homelab's advertised subnets without it). "client" loosens reverse-path
  # filtering, which subnet routes and exit nodes need. openFirewall: its UDP port, so peers can
  # connect directly instead of through a slow DERP relay
  services.tailscale = { enable = true; useRoutingFeatures = "client"; openFirewall = true; };
  # Without resolved, Tailscale takes over /etc/resolv.conf with only its own 100.100.100.100, so
  # all DNS broke with it. With it, only tailnet names go to Tailscale (NetworkManager uses it too)
  services.resolved.enable = true;

  services.printing.enable = true;
  services.avahi = { enable = true; nssmdns4 = true; openFirewall = true; };

  time.timeZone = "Europe/Brussels";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings.LC_TIME = "en_GB.UTF-8";

  users.users.ben = {
    isNormalUser = true;
    description = "Ben";
    # dialout: /dev/ttyACM* (Web Serial flashing, e.g. the Xteink's ESP32)
    # kvm: hardware acceleration for the Android emulator
    extraGroups = [ "networkmanager" "wheel" "video" "dialout" "kvm" ];
  };

  # Git; identity, editor and GitHub login are in ~/.config/git/config (shared with the tablet)
  programs.git.enable = true;

  # Shells: bash stays the login shell (and for scripts); foot starts fish (~/.config/fish)
  programs.fish.enable = true;
  # Not ~250 man-page-to-completion builds on every update (the long "fish-completions" part of
  # rb): fish ships its own, packages bring theirs, and fish makes the rest itself on first start
  programs.fish.generateCompletions = false;
  # Two more builds on every rebuild that changes a package: the man page index (fish turns it on;
  # it's for `man -k`/apropos and fish's command descriptions) and the NixOS options manual
  # (`man configuration.nix`, nixos-help): search.nixos.org instead
  documentation.man.cache.enable = false;
  documentation.nixos.enable = false;
  # ~/.local/bin (my commands: cu, term) in PATH for the whole session, not just shells: greetd
  # sources /etc/profile, so sway and everything it starts (Thunar's terminal, power.sh) find them
  environment.localBinInPath = true;
  # NixOS has no /bin/bash, so scripts with `#!/bin/bash` fail; point it at the system bash
  systemd.tmpfiles.rules = [ "L+ /bin/bash - - - - ${pkgs.bashInteractive}/bin/bash" ];

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

  # ── Audio ───────────────────────────────────────────
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa = { enable = true; support32Bit = true; };
    pulse.enable = true;
  };

  # ── Power ───────────────────────────────────────────
  # Idle is handled by swayidle in the sway config; the laptop's lid and hibernate in laptop.nix
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # ── Nix ─────────────────────────────────────────────
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
    };
    optimise.automatic = true;
  };
  nixpkgs.config.allowUnfree = true;

  # ── Software from outside Nix ───────────────────────
  # Programs downloaded outside Nix (VSCodium extensions' own binaries, pip/npm native modules,
  # generic Linux builds) expect a normal dynamic loader in /lib64: nix-ld provides one
  programs.nix-ld.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
    # Extra libraries AppImages expect in /usr/lib
    package = pkgs.appimage-run.override {
      # Nuvio's player bridge (libplayer_bridge.so) needs libmpv.so.2 and webkit2gtk-4.1
      extraPkgs = pkgs: [ pkgs.mpv-unwrapped pkgs.webkitgtk_4_1 ];
    };
  };
  services.flatpak.enable = true;   # apps in ~/.config/flatpak/apps, installed by rb
  # Flatpak turns on fonts.fontDir, which rebuilds Xwayland with that font path (minutes, on
  # every update). The cached one: only old X11 core-font apps would miss those fonts
  programs.xwayland.package = pkgs.xwayland;

  system.stateVersion = "26.05";
}
