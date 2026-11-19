{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "ytmusic" ''
      exec ${pkgs.electron}/bin/electron ${./webapps}/ytmusic "$@"
    '')
    (pkgs.makeDesktopItem {
      name = "ytmusic";
      desktopName = "YouTube Music";
      comment = "YouTube Music web player";
      categories = [ "AudioVideo" "Audio" "Player" ];
      exec = "ytmusic";
      icon = "${./webapps}/ytmusic/icon.png";
      startupWMClass = "ytmusic";
    })
  ];
}
