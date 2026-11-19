# AI apps, desktop only: switch each on below and rebuild. Their data on /mnt/nvme stays while off
{ lib, pkgs, isLaptop, ... }:

let
  unsloth = false;
  upscayl = false;
in
{
  config = lib.mkIf (!isLaptop) (lib.mkMerge [
    (lib.mkIf unsloth {
      systemd.tmpfiles.rules = [
        "d /mnt/nvme/Documents/unsloth 0755 ben users -"
        "d /mnt/nvme/Documents/huggingface 0755 ben users -"
        "L /home/ben/.unsloth - - - - /mnt/nvme/Documents/unsloth"
        "L /home/ben/.cache/huggingface - - - - /mnt/nvme/Documents/huggingface"
        "L /home/ben/.lmstudio - - - - /mnt/nvme/Documents/lm-studio"   # LM Studio's old GGUFs
      ];
      # Not in 26.05 yet: unstable's package file
      environment.systemPackages = [
        (pkgs.callPackage (builtins.fetchurl
          "https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/un/unsloth-desktop/package.nix") { })
      ];
    })
    (lib.mkIf upscayl {
      environment.systemPackages = [ pkgs.upscayl ];
    })
  ]);
}
