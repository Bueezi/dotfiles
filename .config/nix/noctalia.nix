{ config, lib, pkgs, ... }:

let
  # Umbriel + portal have no releases: their flake follows main, locked until `rb -u`
  flake = builtins.getFlake (toString ./noctalia);

  # Noctalia + greeter: their newest release tag, looked up at each rebuild
  release = repo: rec {
    tag = lib.last (lib.sort (a: b: builtins.compareVersions a b < 0)
      (lib.filter (t: builtins.match "v[0-9.]+" t != null)
        (map (t: t.name) (builtins.fromJSON (builtins.readFile
          (builtins.fetchurl "https://api.github.com/repos/${repo}/tags"))))));
    src = builtins.fetchTarball "https://github.com/${repo}/archive/refs/tags/${tag}.tar.gz";
  };
  noctalia = release "noctalia-dev/noctalia";
  greeter = release "noctalia-dev/noctalia-greeter";
in
{
  imports = [
    flake.nixosModules.umbriel
    "${noctalia.src}/nix/nixos-module.nix"
    "${greeter.src}/nix/nixos-module.nix"
  ];
  nixpkgs.overlays = [
    flake.overlays.default
    (final: prev: {
      noctalia = final.callPackage "${noctalia.src}/nix/package.nix" { rev = noctalia.tag; };
      noctalia-greeter = final.callPackage "${greeter.src}/nix/package.nix" { };
    })
  ];

  programs.umbriel = {
    enable = true;
    package = pkgs.umbriel;
    portalPackage = pkgs.xdg-desktop-portal-umbriel;
  };
  programs.noctalia = {
    enable = true;
    package = pkgs.noctalia;
    recommendedServices.enable = true;   # NetworkManager, Bluetooth, UPower, power-profiles-daemon
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
