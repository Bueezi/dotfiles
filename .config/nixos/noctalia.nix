# The PCs' desktop: Noctalia (shell) on Umbriel (its team's compositor), logged into through
# Noctalia Greeter. Sway stays as a fallback: pick it in the greeter's session list. Umbriel's
# config: ~/.config/umbriel/config.toml. `umbriel-nested` runs it in a window inside another
# session (Mod is Alt there). Packages: ./noctalia/flake.nix.
{ pkgs, ... }:

let
  flake = builtins.getFlake (toString ./noctalia);
in
{
  imports = with flake.nixosModules; [ umbriel noctalia greeter ];
  nixpkgs.overlays = [ flake.overlays.default ];

  programs.umbriel = {
    enable = true;
    package = pkgs.umbriel;
    portalPackage = pkgs.xdg-desktop-portal-umbriel;
  };
  programs.noctalia = {
    enable = true;
    package = pkgs.noctalia;
  };

  # The packaged config at a fixed path, for ~/.config/umbriel/config.toml's include
  # (upstream's module links only share/umbriel/effects)
  environment.pathsToLink = [ "/share/umbriel" ];

  # Looks are its own; Noctalia's Sync copies wallpaper, colours and monitors over
  services.displayManager.noctalia-greeter = {
    enable = true;
    package = pkgs.noctalia-greeter;
    settings = {
      session.default = "umbriel";
      cursor = { theme = "Bibata-Modern-Classic"; size = 20; path = pkgs.bibata-cursors; };   # as in sway.nix
      keyboard.layout = "us";
    };
    passwordless-sync-users = [ "ben" ];   # the appearance-only sync, without a root prompt
  };

  environment.systemPackages = [
    # Umbriel in a window inside sway, on its own D-Bus session so Noctalia doesn't take
    # notifications or the tray from mako/swaybar. No SWAYSOCK/I3SOCK: scripts started in it
    # would drive the real sway. Bus config by path: dbus-run-session looks in /etc/dbus-1, which
    # NixOS doesn't have
    (pkgs.writeShellScriptBin "umbriel-nested" ''
      unset SWAYSOCK I3SOCK DBUS_SESSION_BUS_ADDRESS
      exec ${pkgs.dbus}/bin/dbus-run-session --config-file=/run/current-system/sw/share/dbus-1/session.conf \
        -- ${pkgs.umbriel}/bin/umbriel "$@"
    '')
  ];
}
