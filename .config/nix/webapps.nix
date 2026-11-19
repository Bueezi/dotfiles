{ pkgs, lib, ... }:

let
  apps = {
    ytmusic = { name = "YouTube Music"; comment = "YouTube Music web player"; categories = [ "AudioVideo" "Audio" "Player" ]; };
  };

  webapp = cmd: app: [
    (pkgs.writeShellScriptBin cmd ''
      exec ${pkgs.electron}/bin/electron ${./webapps}/${cmd} "$@"
    '')
    (pkgs.makeDesktopItem {
      name = cmd;
      desktopName = app.name;
      inherit (app) comment categories;
      exec = cmd;
      icon = "${./webapps}/${cmd}/icon.png";
      startupWMClass = cmd;
    })
  ];
in
{
  environment.systemPackages = lib.concatLists (lib.mapAttrsToList webapp apps);
}
