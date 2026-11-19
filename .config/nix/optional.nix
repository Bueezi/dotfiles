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
      # Not in 26.05 yet: unstable's package file. Update: newer rev, then nix-prefetch-url <url>
      environment.systemPackages = [
        (pkgs.callPackage (builtins.fetchurl {
          url = "https://raw.githubusercontent.com/NixOS/nixpkgs/d4f25a3e562008648d45bcf2d70bcc7422cad84e/pkgs/by-name/un/unsloth-desktop/package.nix";
          sha256 = "sha256-VfdGdkOiZmEARRpYyLinXqM2Wnxy3oqh0IJbq5GWgL4=";
        }) { })
      ];
    })
    (lib.mkIf upscayl {
      environment.systemPackages = [ pkgs.upscayl ];
    })
  ]);
}
