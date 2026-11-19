{ pkgs, ... }:

{
  boot = {
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 3;
      systemd-boot.editor = false;   # else anyone at the keyboard can boot init=/bin/sh
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest; # RDNA4 needs a recent kernel
  };

  # Once per machine: `sudo tailscale up --accept-routes`
  services.tailscale = { enable = true; useRoutingFeatures = "client"; openFirewall = true; };
  services.resolved.enable = true;   # else Tailscale takes over all DNS

  services.printing.enable = true;
  services.avahi = { enable = true; nssmdns4 = true; openFirewall = true; };

  time.timeZone = "Europe/Brussels";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings.LC_TIME = "en_GB.UTF-8";

  users.users.ben = {
    isNormalUser = true;
    description = "Ben";
    extraGroups = [ "networkmanager" "wheel" "video" "dialout" "kvm" ];
  };

  programs.git.enable = true;
  environment.variables.EDITOR = "hx";

  programs.fish.enable = true;
  # Build time on every update (CLAUDE.md, rb speed)
  programs.fish.generateCompletions = false;
  documentation.man.cache.enable = false;
  documentation.nixos.enable = false;
  environment.localBinInPath = true;
  systemd.tmpfiles.rules = [ "L+ /bin/bash - - - - ${pkgs.bashInteractive}/bin/bash" ];

  zramSwap.enable = true;

  hardware = {
    graphics = { enable = true; enable32Bit = true; };
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };

  services.fwupd.enable = true;

  # Gamakay NS68 keyboard config over WebHID (gearhub.top). 70-: uaccess must come before 73-seat-late
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/70-gamakay.rules" ''
      KERNEL=="hidraw*", ATTRS{idVendor}=="3151", ATTRS{idProduct}=="502f|5026", TAG+="uaccess"
    '')
  ];

  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa = { enable = true; support32Bit = true; };
    pulse.enable = true;
  };

  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
    };
    optimise.automatic = true;
    # GitHub token (from `gh auth token`) against API rate limits; skipped when missing
    extraOptions = "!include /home/ben/.config/nix/github-token.conf";
  };
  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [ pkgs.mpv-unwrapped pkgs.webkitgtk_4_1 ];   # Nuvio
    };
  };
  services.flatpak.enable = true;

  system.stateVersion = "26.05";
}
