# /etc/nixos/configuration.nix (served at nix.b3n.me)
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
