# /etc/nixos/configuration.nix (served at nix.b3n.me for fresh installs)
# Only per-machine settings live here; everything else is in ~/.configuration.nix.
{ ... }:

let
  # Per-machine toggles — flip these when deploying to the other machine.
  hostName = "nixos"; # e.g. "laptop" / "desktop"
  isLaptop = true;    # true = 7430U laptop, false = 7500F + RX 9070 XT desktop

  # Use the local dotfiles copy so edits apply on the next rebuild. On a fresh
  # install (no dotfiles yet) fetch the whole repo from GitHub instead: .configuration.nix
  # imports its parts from .config/nixos next to it.
  local = /home/ben/.configuration.nix;
  common =
    if builtins.pathExists local then local
    else "${builtins.fetchTarball "https://github.com/Bueezi/dotfiles/archive/main.tar.gz"}/.configuration.nix";
in
{
  imports = [ ./hardware-configuration.nix common ];

  networking.hostName = hostName;
  _module.args.isLaptop = isLaptop;
}
