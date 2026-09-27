# HyprQuickPaper (github.com/ujjalsigdel/hyprquickpaper): a Quickshell wallpaper picker, set up
# for awww. Command `hyprquickpaper` ($mod+Shift+w). Lists every image under ~/Documents/wp/active,
# subfolders included (./hyprquickpaper/recursive.patch: upstream lists one folder only).
{ pkgs, ... }:

let
  layout = "shell-classic.qml";   # the recursive patch is for this layout only

  src = pkgs.fetchFromGitHub {
    owner = "ujjalsigdel";
    repo = "hyprquickpaper";
    rev = "6f669cd88f29e9d18d431099a67b6e33f55b0df7";
    hash = "sha256-AKH85iNgu/G79emOo+jWv13ySzBunl1XSMtQQivpGyE=";
  };

  config = pkgs.writeText "config.json" (builtins.toJSON {
    wallpaper_path = "~/Documents/wp/active/";
    cache_path = "~/.cache/quickshell/thumbs/";
    wallpaper_tool = "awww";
    number_of_pictures = 7;
    border_color = "#ffffff";   # black and white like the rest
    cache_batch_size = 20;
    stable_copy_path = "";
    video_extensions = [ "mp4" "webm" "mov" "mkv" "gif" ];
    video_thumbnail_interval = 5;
  });

  shell = pkgs.runCommand "hyprquickpaper-shell" { } ''
    cp -r ${src} $out
    chmod -R u+w $out
    cp ${config} $out/config.json
    patch -p1 -d $out < ${./hyprquickpaper/recursive.patch}
    substituteInPlace $out/shell.qml \
      --replace-fail 'property string activeLayout: "shell-classic.qml"' 'property string activeLayout: "${layout}"'
    # awww: random-point transition like before, and remember the pick for login (sway autostart)
    substituteInPlace $out/commands.sh --replace-fail \
      'awww img "$WALLPAPER" --transition-type grow --transition-duration 1 --transition-fps 60' \
      'ln -sfn "$(readlink -f "$WALLPAPER")" "$HOME/.local/state/wallpaper"; awww img "$WALLPAPER" --transition-type any --transition-duration 1.2 --transition-fps 144'
  '';

  hyprquickpaper = pkgs.writeShellScriptBin "hyprquickpaper" ''
    # Tools its scripts call, and Qt5Compat (rounded thumbnails), which isn't part of
    # quickshell's own QML modules
    export PATH=${pkgs.lib.makeBinPath (with pkgs; [ jq imagemagick ffmpeg ])}:$PATH
    export QML_IMPORT_PATH=${pkgs.qt6.qt5compat}/lib/qt-6/qml''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}
    exec ${pkgs.quickshell}/bin/qs -p ${shell}
  '';
in
{
  environment.systemPackages = [ hyprquickpaper ];

  # Slideshow: a random wallpaper from the same folder every 20s, while the timer runs, and only
  # while the wallpaper can be seen.
  # Toggled from the power menu (power.sh → slideshow), which touches/removes ~/.config/slideshow;
  # sway starts the timer at login if that file exists.
  systemd.user.services.wallpaper-slideshow = {
    description = "Random wallpaper from ~/Documents/wp/active";
    path = with pkgs; [ awww findutils coreutils gnugrep jq sway ];
    serviceConfig.Type = "oneshot";
    script = ''
      # Only while the wallpaper is visible: skip if the focused workspace has a tiled window
      # (it fills the screen) or anything is fullscreen
      export SWAYSOCK=''${SWAYSOCK:-$(ls /run/user/$(id -u)/sway-ipc.*.sock 2>/dev/null | head -1)}
      [ "$(swaymsg -t get_workspaces | jq '.[] | select(.focused) | .representation')" = null ] || exit 0
      [ "$(swaymsg -t get_tree | jq '[.. | objects | select(.pid? and .fullscreen_mode == 1)] | length')" = 0 ] || exit 0

      f=$(find -L "$HOME/Documents/wp/active" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) |
        grep -vxF "$(readlink -f "$HOME/.local/state/wallpaper")" | shuf -n1)
      [ -n "$f" ] || exit 0
      ln -sfn "$f" "$HOME/.local/state/wallpaper"
      awww img "$f" --transition-type any --transition-duration 1.2 --transition-fps 144
    '';
  };
  systemd.user.timers.wallpaper-slideshow.timerConfig = {
    OnActiveSec = "20s";
    OnUnitActiveSec = "20s";
    AccuracySec = "1s";
  };
}
