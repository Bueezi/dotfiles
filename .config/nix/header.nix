# Imported by the /etc/nixos stub (~/.config/scripts/configuration.nix), which sets hostName and isLaptop
{ ... }:

{
  imports = [
    ./base.nix
    ./session.nix
    ./packages.nix
    ./dev.nix
    ./tools.nix
    ./laptop.nix
    ./desktop.nix
    ./gaming.nix
    ./optional.nix
    ./librewolf.nix
    ./webapps.nix
    ./noctalia.nix
  ];
}
