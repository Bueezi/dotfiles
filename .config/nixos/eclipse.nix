# Eclipse Music web player as a desktop app (tray icon, close = hide), see ./eclipse/main.js.
# Runs the page in nixpkgs' Electron; installs an `eclipse` command and an app-menu entry.
{ pkgs, ... }:

let
  eclipse = pkgs.writeShellScriptBin "eclipse" ''
    exec ${pkgs.electron}/bin/electron ${./eclipse} "$@"
  '';

  desktopItem = pkgs.makeDesktopItem {
    name = "eclipse";
    desktopName = "Eclipse";
    comment = "Eclipse Music web player";
    exec = "eclipse";
    icon = "${./eclipse/icon.png}";
    categories = [ "AudioVideo" "Audio" "Player" ];
    startupWMClass = "eclipse";
  };
in
{
  environment.systemPackages = [ eclipse desktopItem ];
}
