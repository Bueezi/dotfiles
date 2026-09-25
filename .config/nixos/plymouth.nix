# Boot splash: the penguin-vs-Windows clip (./plymouth/boot.mp4), looping in a small box in
# the centre of a black screen. Frames are cut from the mp4 at build time.
# Esc during boot switches to the text log; a failed boot drops the splash by itself.
{ pkgs, ... }:

let
  width = 480;  # px, like an OEM logo
  fps = 15;

  theme = pkgs.runCommand "plymouth-penguin" { nativeBuildInputs = [ pkgs.ffmpeg-headless ]; } ''
    dir=$out/share/plymouth/themes/penguin
    mkdir -p $dir
    # Cut off the bottom 70px (AI watermark), scale down, drop to ${toString fps} fps
    ffmpeg -v error -i ${./plymouth/boot.mp4} \
      -vf "crop=iw:ih-70:0:0,fps=${toString fps},scale=${toString width}:-2" $dir/frame-%03d.png

    frames=$(ls $dir/frame-*.png | wc -l)
    substitute ${./plymouth/penguin.script} $dir/penguin.script \
      --replace-fail @frames@ "$frames" --replace-fail @fps@ ${toString fps}

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

  # Quiet, flicker-free boot so the splash isn't covered by text
  boot.initrd.systemd.enable = true;     # smoother handover to plymouth
  boot.initrd.kernelModules = [ "amdgpu" ]; # GPU driver early: no resolution switch mid-splash
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 3;              # kernel errors still show, nothing else
  boot.kernelParams = [ "quiet" "splash" "udev.log_level=3" "systemd.show_status=auto" ];
}
