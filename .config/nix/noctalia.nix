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

  # For ~/.config/umbriel/config.toml's include of the packaged config
  environment.pathsToLink = [ "/share/umbriel" ];

  services.displayManager.noctalia-greeter = {
    enable = true;
    package = pkgs.noctalia-greeter;
    settings = {
      session.default = "umbriel";
      user.default = "ben";
      cursor = with config.environment.sessionVariables; {
        theme = XCURSOR_THEME; size = lib.toInt XCURSOR_SIZE; path = pkgs.bibata-cursors;
      };
      keyboard.layout = "us";
      appearance = {
        password_style = "random";
        hide_logo = true;
        scheme_selector_position = "hidden";
      };
      clock = { time_format = "%H:%M:%S"; date_format = "%A %-d %B"; };
    };
    passwordless-sync-users = [ "ben" ];
  };

  environment.systemPackages = [
    # Own D-Bus session, else its Noctalia takes the real one's notifications and tray
    (pkgs.writeShellScriptBin "umbriel-nested" ''
      unset UMBRIEL_SOCKET DBUS_SESSION_BUS_ADDRESS
      exec ${pkgs.dbus}/bin/dbus-run-session --config-file=/run/current-system/sw/share/dbus-1/session.conf \
        -- ${pkgs.umbriel}/bin/umbriel "$@"
    '')
  ];
}
