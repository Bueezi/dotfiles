# NixOS for the desktop PC and the laptop: the parts are in ~/.config/nixos, one file per topic.
# Imported by the /etc/nixos stub (~/.config/scripts/configuration.nix), which sets hostName and
# isLaptop. Each machine's own things are in laptop.nix / desktop.nix (and gaming.nix, desktop only)
{ ... }:

{
  imports = [
    ./.config/nixos/base.nix      # boot, network, users, Nix, audio, power
    ./.config/nixos/sway.nix      # the session: SwayFX, login, portals, themes, default apps, fonts
    ./.config/nixos/packages.nix  # apps and command-line tools
    ./.config/nixos/dev.nix       # editors, language servers, containers, Android, Lean, LaTeX
    ./.config/nixos/laptop.nix
    ./.config/nixos/desktop.nix
    ./.config/nixos/gaming.nix
    ./.config/nixos/librewolf.nix       # LibreWolf with ~/.config/librewolf's prefs and policies
    ./.config/nixos/swayfx.nix          # latest SwayFX from git
    ./.config/nixos/plymouth.nix        # boot splash (penguin video)
    ./.config/nixos/webapps.nix         # YouTube Music as a desktop app
    ./.config/nixos/hyprquickpaper.nix  # wallpaper picker ($mod+Shift+w), slideshow
  ];
}
