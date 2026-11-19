{ config, lib, pkgs, isLaptop, ... }:

let
  script = name: runtimeInputs: pkgs.writeShellApplication {
    inherit name runtimeInputs;
    text = builtins.readFile ./gaming/${name}.sh;
    bashOptions = [ ];
  };

  acmanagerLinks = pkgs.makeDesktopItem {
    name = "acmanager";
    desktopName = "Content Manager link";
    noDisplay = true;
    mimeTypes = [ "x-scheme-handler/acmanager" ];
    exec = "${script "acmanager" [ pkgs.procps config.programs.steam.package pkgs.systemd pkgs.umbriel pkgs.jq pkgs.libnotify ]}/bin/acmanager %u";
  };

  # Discord's game list for steam-rpc.py, from Vesktop's arRPC at build time
  steamRpcGames = pkgs.runCommand "steam-rpc-games.tsv" { nativeBuildInputs = [ pkgs.asar ]; } ''
    asar extract-file ${pkgs.vesktop}/opt/Vesktop/resources/app.asar dist/js/arRpcWorker.js.map
    ${pkgs.python3}/bin/python3 -I ${./gaming/steam-rpc.py} --build arRpcWorker.js.map > $out
  '';

  # No runtimeInputs: their PATH would reach the game
  gamescopeSdl = script "gamescope-sdl" [ ];
in
{
  config = lib.mkIf (!isLaptop) {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
    # No GPU settings: amd_performance_level=high gave artefacts and clock swings in CS2
    programs.gamemode.enable = true;
    users.users.ben.extraGroups = [ "gamemode" ];
    # No capSysNice: its wrapper can't run in Steam's sandbox, gamescope then fails
    programs.gamescope.enable = true;

    environment.systemPackages = with pkgs; [
      mangohud
      protontricks
      acmanagerLinks
      gamescopeSdl
      oversteer
    ];
    xdg.mime.defaultApplications."x-scheme-handler/acmanager" = "acmanager.desktop";

    # Native Steam games in Discord (arRPC only spots Windows .exe names)
    systemd.user.services.steam-rpc = {
      description = "Discord Rich Presence for native Steam games";
      wantedBy = [ "default.target" ];
      path = [ pkgs.coreutils ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 -I ${./gaming/steam-rpc.py} ${steamRpcGames}";
        Restart = "always";
        RestartSec = 10;
      };
    };

    # G920 out of Xbox mode
    hardware.usb-modeswitch.enable = true;
    services.udev.packages = [ pkgs.oversteer ];
  };
}
