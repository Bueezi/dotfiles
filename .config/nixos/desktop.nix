# Desktop PC only (Ryzen 5 7500F + RX 9070 XT, isLaptop = false): drives, RGB, monitor, GPU, apps.
# Games: gaming.nix
{ lib, pkgs, isLaptop, ... }:

{
  config = lib.mkIf (!isLaptop) {
    fileSystems."/mnt/nvme" = {
      device = "/dev/disk/by-uuid/b2eb90c5-7585-4519-83e9-91808d894f17";   # from `blkid /dev/nvme0n1p3`
      fsType = "ext4";
      options = [ "nofail" "x-systemd.device-timeout=5s" "x-gvfs-show" "x-gvfs-name=nvme" ];
    };
    fileSystems."/mnt/hdd" = {
      device = "/dev/disk/by-uuid/005AA8F65AA8EA1C";
      fsType = "ntfs3";   # the kernel's own NTFS driver, faster than ntfs-3g
      options = [
        "nofail" "x-systemd.device-timeout=5s"
        "uid=1000" "gid=100" "umask=022"   # NTFS has no Linux owners: make everything yours
        "x-gvfs-show" "x-gvfs-name=hdd"
      ];
    };
    # LM Studio keeps its models etc. in ~/.lmstudio: point that at the nvme
    systemd.tmpfiles.rules = [ "L /home/ben/.lmstudio - - - - /mnt/nvme/Documents/lm-studio" ];

    # RAM RGB: OpenRGB reaches the DIMMs over SMBus through /dev/i2c-* (i2c-dev).
    # spd5118 (DDR5 SPD/temperature driver) claims the sticks' SPD addresses, which makes
    # OpenRGB skip them, so keep it off (costs the RAM temperature sensor).
    boot.kernelModules = [ "i2c-dev" ];
    boot.blacklistedKernelModules = [ "spd5118" ];
    # /dev/i2c-* for the i2c group too: ddcutil sets the monitor's brightness over DDC/CI
    hardware.i2c.enable = true;
    users.users.ben.extraGroups = [ "i2c" ];

    systemd.services.rgb-off = {
      description = "Turn off RGB lighting";
      wantedBy = [ "multi-user.target" "suspend.target" ];
      after = [ "systemd-modules-load.service" "suspend.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.openrgb}/bin/openrgb --noautoconnect -m off";
      };
    };

    # GPU control (fan curves, power limit, undervolt): LACT app + its daemon
    services.lact.enable = true;

    environment.systemPackages = with pkgs; [
      upscayl               # AI image upscaler
      openrgb               # RGB control GUI/CLI (rgb-off above uses its own store path)
      rocmPackages.rocm-smi # GPU monitoring
      ddcutil               # monitor brightness over DDC/CI (osd.sh brightness)
      lmstudio              # local LLMs; data/models live on the nvme (see tmpfiles above)
    ];
    # Let OpenRGB reach the RGB devices without root
    services.udev.packages = [ pkgs.openrgb ];
  };
}
