# /etc/nixos/configuration.nix (served at nix.b3n.me)
#
# Manual LUKS install:
#   sudo -i
#   gdisk commands(no swap part)
#
#   mkfs.fat -F32 -n boot DISKp1
#   cryptsetup luksFormat DISKp2
#   cryptsetup open --allow-discards --persistent DISKp2 cryptroot    # TRIM through LUKS, saved in its header
#   mkfs.ext4 -L nixos /dev/mapper/cryptroot
#
#   mount /dev/mapper/cryptroot /mnt
#   mount --mkdir -o umask=077 DISKp1 /mnt/boot
#
#   nixos-generate-config --root /mnt
#   curl -L nix.b3n.me -o configuration.nix
#   cp configuration.nix /mnt/etc/nixos/                    # the stub (nix.b3n.me); set hostName, isLaptop
#   nixos-install --option extra-experimental-features 'nix-command flakes'   # the ISO's Nix has flakes off; the config uses getFlake
#   nixos-enter --root /mnt -c 'passwd ben'
#   reboot
#
#   Then as ben (a TTY: the desktop has no config yet), the dotfiles into ~:
#   git clone --bare https://github.com/Bueezi/dotfiles.git ~/.dotfiles
#   git --git-dir=$HOME/.dotfiles --work-tree=$HOME config --local status.showUntrackedFiles no
#   git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout
#   rb              # now from ~/.config/nix, not the GitHub copy
#   gh auth login   # for cu (pushes, private ~/Documents/sync)
#   cu
#   log in to the desktop again (quit Umbriel: Mod+Shift+M)
#
#   After: cryptsetup luksHeaderBackup DISKp2 --header-backup-file luks-header.img  (keep it off this disk)
#
#   No typing at boot (TPM2, optional; weak without Secure Boot, passphrase stays as fallback):
#   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 DISKp2
#   /etc/nixos/hardware-configuration.nix, in the luks-... entry:  crypttabExtraOpts = [ "tpm2-device=auto" ];
#   then rebuild. Undo: sudo systemd-cryptenroll --wipe-slot=tpm2 DISKp2
#
#   Secure Boot (Lanzaboote; do it before the TPM enroll above, which binds to PCR 7 = SB state):
#   sudo sbctl create-keys
#   base.nix: import Lanzaboote's module, boot.loader.systemd-boot.enable = lib.mkForce false;
#             boot.lanzaboote = { enable = true; pkiBundle = "/var/lib/sbctl"; };   rebuild, sudo sbctl verify
#   firmware: clear Secure Boot keys (Setup Mode)
#   sudo sbctl enroll-keys --microsoft     # keep --microsoft: GPU option ROM is MS-signed, else no display/boot
#   firmware: enable Secure Boot, check with bootctl status
#   Ventoy then needs its key enrolled (MOK) or SB off to boot.

{ ... }:

let
  hostName = "nixos";
  isLaptop = true;    # true = 7430U laptop, false = 7500F + RX 9070 XT desktop

  # Fresh install: the repo from GitHub
  local = /home/ben/.config/nix/header.nix;
  common =
    if builtins.pathExists local then local
    else "${builtins.fetchTarball "https://github.com/Bueezi/dotfiles/archive/main.tar.gz"}/.config/nix/header.nix";
in
{
  imports = [ ./hardware-configuration.nix common ];

  networking.hostName = hostName;
  _module.args.isLaptop = isLaptop;
}
