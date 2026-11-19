{ config, lib, pkgs, isLaptop, ... }:

let
  # acmanager:// links (NoHesi "Join") → Content Manager. CM open: through Proton's launcher
  # service (launch option STEAM_COMPAT_LAUNCHER_SERVICE=proton), see CLAUDE.md
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
        id=$(${pkgs.umbriel}/bin/umbriel windows --json | ${pkgs.jq}/bin/jq -r 'map(select(
          (.app_id | test("^(steam_app_244210|assettocorsa\\.exe)$"; "i")) and ((.title // "") | test("content manager"; "i"))))
          | first | .id // empty')
        [ -z "$id" ] || ${pkgs.umbriel}/bin/umbriel msg window-focus "$id" >/dev/null
        exit 0
      fi
      ${pkgs.libnotify}/bin/notify-send -a acmanager -i dialog-information-symbolic "Content Manager is open" \
        "Can't pass it the link: add STEAM_COMPAT_LAUNCHER_SERVICE=proton to AC's launch options, or close CM and click again"
    ''} %u";
  };

  # Discord's game list for steam-rpc.py, from Vesktop's arRPC at build time
  steamRpcGames = pkgs.runCommand "steam-rpc-games.tsv" { nativeBuildInputs = [ pkgs.asar ]; } ''
    asar extract-file ${pkgs.vesktop}/opt/Vesktop/resources/app.asar dist/js/arRpcWorker.js.map
    ${pkgs.python3}/bin/python3 -I ${./steam-rpc.py} --build arRpcWorker.js.map > $out
  '';

  # `gamescope-sdl <options> -- %command%`: SDL backend without Steam's LD_* (CLAUDE.md, CS2)
  gamescopeSdl = pkgs.writeShellScriptBin "gamescope-sdl" ''
    opts=()
    while [ $# -gt 0 ] && [ "$1" != -- ]; do opts+=("$1"); shift; done
    shift
    exec ${pkgs.coreutils}/bin/env -u LD_PRELOAD -u LD_LIBRARY_PATH \
      ${config.programs.gamescope.package}/bin/gamescope --backend sdl "''${opts[@]}" -- \
      ${pkgs.coreutils}/bin/env LD_PRELOAD="''${LD_PRELOAD-}" LD_LIBRARY_PATH="''${LD_LIBRARY_PATH-}" "$@"
  '';
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
        ExecStart = "${pkgs.python3}/bin/python3 -I ${./steam-rpc.py} ${steamRpcGames}";
        Restart = "always";
        RestartSec = 10;
      };
    };

    # G920 out of Xbox mode
    hardware.usb-modeswitch.enable = true;
    services.udev.packages = [ pkgs.oversteer ];
  };
}
