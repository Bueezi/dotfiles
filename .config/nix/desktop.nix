{ lib, pkgs, isLaptop, ... }:

{
  config = lib.mkIf (!isLaptop) {
    fileSystems."/mnt/nvme" = {
      device = "/dev/disk/by-uuid/b2eb90c5-7585-4519-83e9-91808d894f17";
      fsType = "ext4";
      options = [ "nofail" "x-systemd.device-timeout=5s" "x-gvfs-show" "x-gvfs-name=nvme" ];
    };
    fileSystems."/mnt/hdd" = {
      device = "/dev/disk/by-uuid/005AA8F65AA8EA1C";
      fsType = "ntfs3";
      options = [
        "nofail" "x-systemd.device-timeout=5s"
        "uid=1000" "gid=100" "umask=022"
        "x-gvfs-show" "x-gvfs-name=hdd"
      ];
    };
    boot.kernelModules = [ "i2c-dev" ];
    # Claims the RAM's SPD addresses, so OpenRGB skipped the sticks
    boot.blacklistedKernelModules = [ "spd5118" ];
    hardware.i2c.enable = true;
    services.displayManager.noctalia-greeter.settings.output.refresh_rate = "DP-2:180";   # else 60 Hz
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

    services.lact.enable = true;

    environment.systemPackages = with pkgs; [
      openrgb
      rocmPackages.rocm-smi
      (lib.hiPrio (btop.override { rocmSupport = true; }))
      ddcutil
    ];
    services.udev.packages = [ pkgs.openrgb ];
  };
}
