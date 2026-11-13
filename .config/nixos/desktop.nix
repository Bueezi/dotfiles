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
    # Unsloth Studio keeps its runtime (venv, PyTorch, llama.cpp) in ~/.unsloth and models in the
    # Hugging Face cache: both on the nvme. ~/.lmstudio stays so Studio finds LM Studio's old GGUFs
    systemd.tmpfiles.rules = [
      "d /mnt/nvme/Documents/unsloth 0755 ben users -"
      "d /mnt/nvme/Documents/huggingface 0755 ben users -"
      "L /home/ben/.unsloth - - - - /mnt/nvme/Documents/unsloth"
      "L /home/ben/.cache/huggingface - - - - /mnt/nvme/Documents/huggingface"
      "L /home/ben/.lmstudio - - - - /mnt/nvme/Documents/lm-studio"
    ];

    # RAM RGB: OpenRGB reaches the DIMMs over SMBus through /dev/i2c-* (i2c-dev).
    # spd5118 (DDR5 SPD/temperature driver) claims the sticks' SPD addresses, which makes
    # OpenRGB skip them, so keep it off (costs the RAM temperature sensor).
    boot.kernelModules = [ "i2c-dev" ];
    boot.blacklistedKernelModules = [ "spd5118" ];
    # /dev/i2c-* for the i2c group too: ddcutil sets the monitor's brightness over DDC/CI
    hardware.i2c.enable = true;
    # The login screen takes the EDID-preferred mode, which on this monitor is 60 Hz
    services.displayManager.noctalia-greeter.settings.output.refresh_rate = "DP-2:180";
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
      # btop with the GPU (it loads rocm-smi's library, which plain btop can't find), over
      # packages.nix's btop. On cache.nixos.org, so nothing to build
      (lib.hiPrio (btop.override { rocmSupport = true; }))
      ddcutil               # monitor brightness over DDC/CI (Noctalia's brightness)
      # Unsloth Studio (local LLMs: chat + fine-tuning; ROCm on the 9070 XT), not in 26.05 yet:
      # nixpkgs-unstable's package file, built with the system nixpkgs. Newer = a newer rev + its
      # hash (nix-prefetch-url <url>, then nix hash convert --hash-algo sha256 <it>).
      # Data/models live on the nvme (see tmpfiles above)
      (callPackage (builtins.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixpkgs/d4f25a3e562008648d45bcf2d70bcc7422cad84e/pkgs/by-name/un/unsloth-desktop/package.nix";
        sha256 = "sha256-VfdGdkOiZmEARRpYyLinXqM2Wnxy3oqh0IJbq5GWgL4=";
      }) { })
    ];
    # Let OpenRGB reach the RGB devices without root
    services.udev.packages = [ pkgs.openrgb ];
  };
}
