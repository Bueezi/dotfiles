# Trying out Noctalia (shell) on Umbriel (its team's compositor), next to sway, with upstream's
# defaults: nothing here follows the sway look. Pick "Umbriel" in tuigreet (F3), or run
# `umbriel-nested` inside sway for a window (Mod is Alt there, Super in a real session).
# Packages: ./noctalia/flake.nix. To drop it all: remove this file from ~/.configuration.nix.
{ pkgs, ... }:

let
  flake = builtins.getFlake (toString ./noctalia);
in
{
  imports = [ flake.nixosModules.umbriel flake.nixosModules.noctalia ];
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

  # Umbriel's packaged config, plus starting Noctalia (upstream leaves that to the user). In
  # /etc/xdg, so a ~/.config/umbriel/config.toml (e.g. a copy of the packaged one) takes over
  environment.etc."xdg/umbriel/config.toml".text = ''
    [include]
    files = ["${pkgs.umbriel}/share/umbriel/config.toml"]

    [general]
    autostart = ["noctalia"]
  '';

  environment.systemPackages = [
    pkgs.kitty   # Umbriel's default terminal (Mod+Return)
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
