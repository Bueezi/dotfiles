# Games, desktop PC only: Steam and its Protons, the G920 wheel, Assetto Corsa's links
{ config, lib, pkgs, isLaptop, ... }:

let
  # Assetto Corsa: acmanager:// links on websites (NoHesi "Join", server lists) open in Content
  # Manager. CM registers them only inside its Proton prefix, so the browser had no handler. CM closed:
  # the link goes through Steam (-applaunch), which starts AC normally (its Proton, launch options)
  # with the link as argument, like CM's own Windows handler. CM open: Steam won't start a running game
  # twice, and its wineserver socket is in the sandbox's private /tmp. So the launch option
  # STEAM_COMPAT_LAUNCHER_SERVICE=proton makes Proton run Valve's launcher service in the game's
  # container (D-Bus com.steampowered.App244210); a second CM started through it, in the same
  # wineserver, hands the link to the open one (CM is single-instance)
  acmanagerLinks = pkgs.makeDesktopItem {
    name = "acmanager";
    desktopName = "Content Manager link";
    noDisplay = true;
    mimeTypes = [ "x-scheme-handler/acmanager" ];
    exec = "${pkgs.writeShellScript "acmanager" ''
      if ! ${pkgs.procps}/bin/pgrep -f 'AssettoCorsa\.exe' >/dev/null; then
        exec ${config.programs.steam.package}/bin/steam -applaunch 244210 "$1"
      fi
      # Steam's own copy (runs through nix-ld)
      client=~/.local/share/Steam/steamrt64/pv-runtime/steam-runtime-steamrt/pressure-vessel/bin/steam-runtime-launch-client
      if ${pkgs.systemd}/bin/busctl --user status com.steampowered.App244210 >/dev/null 2>&1 &&
         "$client" --inside-app=244210 \
           -c 'cd "$STEAM_COMPAT_INSTALL_PATH" && exec wine AssettoCorsa.exe "$1"' acmanager "$1"; then
        ${config.programs.sway.package}/bin/swaymsg -q \
          '[class="(?i)^(steam_app_244210|assettocorsa\.exe)$" title="(?i)content manager"] focus'
        exit 0
      fi
      ${pkgs.libnotify}/bin/notify-send -a acmanager -i dialog-information-symbolic "Content Manager is open" \
        "Can't pass it the link: add STEAM_COMPAT_LAUNCHER_SERVICE=proton to AC's launch options, or close CM and click again"
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
      # Proton-GE, pick it per game in Properties > Compatibility. (Assetto Corsa runs on Valve's
      # Proton 9.0, installed from Steam: Wine 10+ blocks writing to executable memory (W^X), so
      # Custom Shaders Patch can't patch acs.exe, and GE-Proton9-20's DXVK can't share video textures)
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
    # Performance mode while a game runs: launch option `gamemoderun %command%`.
    # Its CPU changes go through polkit, which allows them only for the gamemode group.
    # (No GPU settings: its amd_performance_level=high made the RX 9070 XT's clock swing
    # between 78 and 2520 MHz, with artefacts and ~120 fps in CS2)
    programs.gamemode.enable = true;
    users.users.ben.extraGroups = [ "gamemode" ];
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
