# The PCs' desktop: Noctalia (shell) on Umbriel (its team's compositor), logged into through
# Noctalia Greeter. Umbriel's config: ~/.config/umbriel/config.toml. `umbriel-nested` runs it in a
# window inside the running session (Mod is Alt there). Packages: ./noctalia/flake.nix. The rest of
# the desktop (themes, portals, fonts, default apps): session.nix
{ config, lib, pkgs, ... }:

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
      user.default = "ben";   # straight to the password, no user picker
      cursor = with config.environment.sessionVariables; {   # session.nix's
        theme = XCURSOR_THEME; size = lib.toInt XCURSOR_SIZE; path = pkgs.bibata-cursors;
      };
      keyboard.layout = "us";
      appearance = {
        password_style = "random";
        hide_logo = true;
        scheme_selector_position = "hidden";   # always the synced wallpaper colours
      };
      clock = { time_format = "%H:%M:%S"; date_format = "%A %-d %B"; };
    };
    passwordless-sync-users = [ "ben" ];   # the appearance-only sync, without a root prompt
  };

  environment.systemPackages = [
    # Umbriel in a window, on its own D-Bus session so its Noctalia doesn't take notifications or
    # the tray from the real one. No UMBRIEL_SOCKET: scripts started in it would drive the real
    # Umbriel. Bus config by path: dbus-run-session looks in /etc/dbus-1, which NixOS doesn't have
    (pkgs.writeShellScriptBin "umbriel-nested" ''
      unset UMBRIEL_SOCKET DBUS_SESSION_BUS_ADDRESS
      exec ${pkgs.dbus}/bin/dbus-run-session --config-file=/run/current-system/sw/share/dbus-1/session.conf \
        -- ${pkgs.umbriel}/bin/umbriel "$@"
    '')
  ];
}
