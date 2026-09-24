# Spatial audio for Nuvio: movies' 5.1/7.1 sound becomes 3D sound on headphones.
#
# PipeWire creates a virtual 7.1 output, "Spatial Headphones (Nuvio)". Each channel is
# placed at its speaker angle around your head with an HRTF (the MIT KEMAR dummy-head
# set shipped by libmysofa, which PipeWire already uses) and mixed down to 2 ears.
# Only Nuvio is sent there; it's idle (suspended) when nothing plays to it.
{ lib, pkgs, ... }:

let
  hrtf = "${pkgs.libmysofa}/share/libmysofa/MIT_KEMAR_normal_pinna.sofa";

  # 7.1 channels (PipeWire order) and the angle of each speaker, 0° = front, 90° = left
  channels = [ "FL" "FR" "FC" "LFE" "RL" "RR" "SL" "SR" ];
  azimuth = { FL = 30; FR = 330; FC = 0; LFE = 0; RL = 150; RR = 210; SL = 90; SR = 270; };

  # 8 channels are summed into each ear and the HRTF boosts ~3 kHz, so each channel is
  # turned down to leave headroom. Measured with the same full-volume sound on all 8
  # channels (never happens in real movies): 0.5 clips by ~7 dB, 0.3 by ~2 dB.
  # Raise it if Nuvio is too quiet, lower it if loud scenes crackle.
  gains = lib.listToAttrs (lib.imap1 (i: _: lib.nameValuePair "Gain ${toString i}" 0.3) channels);
in
{
  services.pipewire.extraConfig.pipewire."90-nuvio-surround"."context.modules" = [{
    name = "libpipewire-module-filter-chain";
    args = {
      "node.description" = "Spatial Headphones (Nuvio)";
      "media.name" = "Spatial Headphones (Nuvio)";
      "filter.graph" = {
        nodes = map (ch: {
          type = "sofa";
          label = "spatializer";
          name = "sp${ch}";
          config.filename = hrtf;
          control = { Azimuth = azimuth.${ch} * 1.0; Elevation = 0.0; Radius = 3.0; };
        }) channels ++ [
          { type = "builtin"; label = "mixer"; name = "mixL"; control = gains; }
          { type = "builtin"; label = "mixer"; name = "mixR"; control = gains; }
        ];
        links = lib.concatLists (lib.imap1 (i: ch: [
          { output = "sp${ch}:Out L"; input = "mixL:In ${toString i}"; }
          { output = "sp${ch}:Out R"; input = "mixR:In ${toString i}"; }
        ]) channels);
        inputs = map (ch: "sp${ch}:In") channels;
        outputs = [ "mixL:Out" "mixR:Out" ];
      };
      "capture.props" = {
        "node.name" = "nuvio_surround";
        "media.class" = "Audio/Sink";
        "audio.channels" = 8;
        "audio.position" = channels;
      };
      "playback.props" = {
        "node.name" = "nuvio_surround.output";
        "node.passive" = true;   # don't keep the sound card awake when idle
        "audio.channels" = 2;
        "audio.position" = [ "FL" "FR" ];
        "stream.dont-remix" = true;
      };
    };
  }];

  # Nuvio's built-in mpv reads this to pick its output; if the spatial output is
  # missing, mpv falls back to the normal one. Nothing else uses this variable.
  environment.sessionVariables.NUVIO_MPV_AUDIO_DEVICE = "pipewire/nuvio_surround";
}
