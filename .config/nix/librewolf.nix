{ lib, isLaptop, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      librewolf = prev.librewolf.override {
        extraPrefs = builtins.readFile ../librewolf/prefs.js
          # The laptop's GPU can't decode AV1: YouTube then sends VP9
          + lib.optionalString isLaptop ''
            defaultPref("media.av1.enabled", false);
          '';
        extraPolicies = (builtins.fromJSON (builtins.readFile ../librewolf/policies.json)).policies;
      };
    })
  ];
}
