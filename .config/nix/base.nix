{ pkgs, ... }:

{
  # Latest release: its tool is built locally
  imports = [ (builtins.getFlake "github:nix-community/lanzaboote/${(builtins.fromJSON (builtins.readFile
    (builtins.fetchurl "https://api.github.com/repos/nix-community/lanzaboote/releases/latest"))).tag_name}").nixosModules.lanzaboote ];

  boot = {
    loader = {
      timeout = 0;
      systemd-boot.enable = false;   # Lanzaboote instead, which reads the two below
      systemd-boot.configurationLimit = 3;
      systemd-boot.editor = false;   # else anyone at the keyboard can boot init=/bin/sh
      efi.canTouchEfiVariables = true;
    };
    # Keys made at first boot, enrolled by systemd-boot at a boot in Setup Mode
    # (with Microsoft's: the GPU's option ROM is signed by them)
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      autoGenerateKeys.enable = true;
      autoEnrollKeys.enable = true;
    };
    initrd.luks.devices.cryptroot.crypttabExtraOpts = [ "tpm2-device=auto" ];
    kernelPackages = pkgs.linuxPackages_latest; # RDNA4 needs a recent kernel

    plymouth.enable = true;
    initrd.systemd.enable = true;
    initrd.kernelModules = [ "amdgpu" ];   # splash at native resolution
    initrd.verbose = false;
    consoleLogLevel = 3;
    kernelParams = [ "quiet" "udev.log_level=3" "systemd.show_status=auto" ];
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
  documentation.doc.enable = false;   # share/doc only (Rust's HTML docs: ~600 MiB); man pages stay
  environment.localBinInPath = true;
  systemd.tmpfiles.rules = [ "L+ /bin/bash - - - - ${pkgs.bashInteractive}/bin/bash" ];

  zramSwap.enable = true;

  hardware = {
    graphics = { enable = true; enable32Bit = true; };
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };

  services.fwupd.enable = true;
  systemd.services.fwupd-efi.after = [ "generate-sb-keys.service" ];   # signs with Lanzaboote's keys

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
      extraPkgs = pkgs: [
        pkgs.mpv-unwrapped pkgs.webkitgtk_4_1   # Nuvio
        # Beanstalk's sandbox binds only /usr, whose files here are links into the store
        (pkgs.writeShellScriptBin "bwrap" ''
          case "$1" in --version|--help) ;; *) set -- --ro-bind /nix/store /nix/store "$@" ;; esac
          exec ${pkgs.bubblewrap}/bin/bwrap "$@"
        '')
      ];
    };
  };
  # AppImages that update themselves: drop them in ~/.local/share/appimages, the menu follows
  systemd.user.services.appimage-menu = {
    wantedBy = [ "default.target" ];
    unitConfig = { StartLimitIntervalSec = 0; ConditionUser = "!@system"; };   # not the greeter
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellApplication {
        name = "appimage-menu";
        runtimeInputs = with pkgs; [ coreutils gnused findutils squashfsTools ];
        text = builtins.readFile ./appimage-menu.sh;
      }}/bin/appimage-menu";
    };
  };
  systemd.user.paths.appimage-menu = {
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "!@system";
    pathConfig = { PathChanged = "%h/.local/share/appimages"; MakeDirectory = true; };
  };
  services.flatpak.enable = true;
  environment.systemPackages = [ pkgs.sbctl ];

  system.stateVersion = "26.05";
}
