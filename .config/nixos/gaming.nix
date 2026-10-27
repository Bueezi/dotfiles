# Games, desktop PC only: Steam and its Protons, the G920 wheel, Assetto Corsa's links
{ config, lib, pkgs, isLaptop, ... }:

let
  # Assetto Corsa: acmanager:// links on websites (NoHesi "Join", server lists) open in Content
  # Manager. CM registers them only inside its Proton prefix, so the browser had no handler. The link
  # goes through Steam (-applaunch), which starts AC normally (its Proton, launch options) with the
  # link as argument, like CM's own Windows handler. Only while CM is closed: Steam won't start a
  # running game twice, and nothing outside Steam's sandbox can reach a running CM (its wineserver
  # socket is in the sandbox's private /tmp; protontricks-launch started hidden copies instead)
  acmanagerLinks = pkgs.makeDesktopItem {
    name = "acmanager";
    desktopName = "Content Manager link";
    noDisplay = true;
    mimeTypes = [ "x-scheme-handler/acmanager" ];
    exec = "${pkgs.writeShellScript "acmanager" ''
      if ${pkgs.procps}/bin/pgrep -f 'AssettoCorsa\.exe' >/dev/null; then
        ${pkgs.libnotify}/bin/notify-send -a acmanager -i dialog-information-symbolic "Content Manager is open" \
          "Close it and click the link again, or join from its Online tab"
        exit 0
      fi
      exec ${config.programs.steam.package}/bin/steam -applaunch 244210 "$1"
    ''} %u";
  };

  # Factorio in Discord (Vesktop's arRPC finds games by process name, and Discord knows Factorio
  # only as Windows' factorio.exe): launch option `factorio-rpc %command%` runs the Linux game
  # under that name. Steam's wrappers in %command% stay in front; its last word is the game's
  # bin/x64/factorio, a script that starts bin/x64_/factorio
  factorioRpc = pkgs.writeShellScriptBin "factorio-rpc" ''
    exec "''${@:1:$#-1}" bash -c 'exec -a "''${0%/*}/factorio.exe" "''${0%/*}/../x64_/factorio" "$@"' "''${!#}"
  '';
in
{
  config = lib.mkIf (!isLaptop) {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;               # Steam Remote Play
      localNetworkGameTransfers.openFirewall = true; # copy games between PCs on the LAN
      extraCompatPackages = [
        pkgs.proton-ge-bin   # Proton-GE, pick it per game in Properties > Compatibility
        # Assetto Corsa only: Wine 10+ blocks writing to executable memory (W^X), so Custom Shaders
        # Patch can't patch acs.exe ("Failed to tweak Assetto Corsa: Can't find ..."). The last Wine 9 GE
        ((pkgs.proton-ge-bin.override { steamDisplayName = "GE-Proton9-20"; }).overrideAttrs {
          version = "GE-Proton9-20";
          src = pkgs.fetchzip {
            url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-20/GE-Proton9-20.tar.gz";
            hash = "sha256-1twCv81KO1fcRcIb4H7VtAjtcKrX+DymsYdf885eOWo=";
          };
        })
      ];
    };
    # Performance mode while a game runs: launch option `gamemoderun %command%`
    programs.gamemode.enable = true;
    # Micro-compositor for games: HDR, frame limiting, upscaling (`gamescope --hdr-enabled -- %command%`)
    # (No capSysNice: its capability wrapper can't run inside Steam's sandbox, so gamescope
    # fails with "failed to inherit capabilities" and the game exits)
    programs.gamescope.enable = true;

    environment.systemPackages = with pkgs; [
      mangohud              # in-game FPS/temps overlay: `mangohud %command%` in Steam
      protontricks          # Windows fonts/libs into a game's Proton prefix (Content Manager)
      acmanagerLinks        # acmanager:// links (NoHesi "Join") → Content Manager, see the let
      oversteer             # G920 settings: rotation, force feedback, pedal test
      factorioRpc           # Factorio's launch option, see the let
    ];
    xdg.mime.defaultApplications."x-scheme-handler/acmanager" = "acmanager.desktop";

    # Logitech G920: switch it out of Xbox mode so it shows up as a wheel
    hardware.usb-modeswitch.enable = true;
    # Let Oversteer reach the wheel without root
    services.udev.packages = [ pkgs.oversteer ];
  };
}
