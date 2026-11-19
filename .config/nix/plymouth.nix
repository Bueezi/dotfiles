{ lib, pkgs, ... }:

let
  width = 480;
  fps = 15;
  hold = 1.2;   # s on the first frame after the GPU driver is up, while the monitor syncs

  theme = pkgs.runCommand "plymouth-penguin" { nativeBuildInputs = [ pkgs.ffmpeg-headless ]; } ''
    dir=$out/share/plymouth/themes/penguin
    mkdir -p $dir
    # Cut off the bottom 70px (AI watermark), scale down, drop to ${toString fps} fps
    ffmpeg -v error -i ${./plymouth/boot.mp4} \
      -vf "crop=iw:ih-70:0:0,fps=${toString fps},scale=${toString width}:-2" $dir/frame-%03d.png

    frames=$(ls $dir/frame-*.png | wc -l)
    substitute ${./plymouth/penguin.script} $dir/penguin.script \
      --replace-fail @frames@ "$frames" --replace-fail @fps@ ${toString fps} \
      --replace-fail @hold@ ${toString hold}

    cat > $dir/penguin.plymouth <<EOF
    [Plymouth Theme]
    Name=penguin
    ModuleName=script

    [script]
    ImageDir=$dir
    ScriptFile=$dir/penguin.script
    EOF
  '';
in
{
  boot.plymouth = {
    enable = true;
    themePackages = [ theme ];
    theme = "penguin";
  };

  # Holds the login screen until the clip played once, counted from when the GPU driver is up
  systemd.services.plymouth-play-once = {
    description = "Let the boot splash play through once";
    wantedBy = [ "multi-user.target" ];
    before = [ "plymouth-quit.service" "plymouth-quit-wait.service" ];
    unitConfig.ConditionPathExists = "/run/plymouth/pid";
    serviceConfig = { Type = "oneshot"; TimeoutStartSec = 15; };
    script = ''
      frames=$(ls ${theme}/share/plymouth/themes/penguin/frame-*.png | wc -l)
      clip_ms=$(( frames * 1000 / ${toString fps} ))
      awk=${lib.getExe' pkgs.gawk "awk"}
      # The splash is visible from whichever came last: plymouthd starting, or the real GPU
      # driver coming up (kernel log; simpledrm doesn't count, plymouth ignores it)
      plymouth_ms=$(( $($awk '{ print $22 }' /proc/$(cat /run/plymouth/pid)/stat) * 10 ))
      gpu_ms=$(${lib.getExe' pkgs.util-linux "dmesg"} | $awk -F'[][]' \
        '/\[drm\] Initialized/ && !/simpledrm/ { t = $2 } END { printf "%d", t * 1000 }')
      start_ms=$(( gpu_ms > plymouth_ms ? gpu_ms : plymouth_ms ))
      now_ms=$($awk '{ printf "%d", $1 * 1000 }' /proc/uptime)
      hold_ms=${toString (builtins.floor (hold * 1000))}
      left_ms=$(( start_ms + hold_ms + clip_ms + 300 - now_ms ))   # +300ms: loading the frames
      if [ "$left_ms" -gt 0 ]; then
        sleep "$(( left_ms / 1000 )).$(printf %03d $(( left_ms % 1000 )))"
      fi
    '';
  };

  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 3;
  boot.kernelParams = [ "quiet" "udev.log_level=3" "systemd.show_status=auto" ];
}
