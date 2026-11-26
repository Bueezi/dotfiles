{ lib, isLaptop, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      librewolf = prev.librewolf.override {
        # LibreWolf's cfg sandboxes autoconfig (no Components): the code in prefs.js needs it off.
        # Only read here, before the cfg runs
        extraAutoConfig = ''pref("general.config.sandbox_enabled", false);'';
        extraPrefs = builtins.readFile ../librewolf/prefs.js
          # The laptop's GPU can't decode AV1: YouTube then sends VP9
          + lib.optionalString isLaptop ''
            defaultPref("media.av1.enabled", false);
          '';
        extraPolicies = (builtins.fromJSON (builtins.readFile ../librewolf/policies.json)).policies;
        # Noctalia's Pywalfox host themes it from the wallpaper. LibreWolf has nixpkgs' MOZ_SYSTEM_DIR
        # patch (the wrapper only assumes it for "firefox*"); without it the host lands in ~/.mozilla
        hasMozSystemDirPatch = true;
        nativeMessagingHosts = [
          (final.writeTextDir "lib/mozilla/native-messaging-hosts/pywalfox.json" (builtins.toJSON {
            name = "pywalfox"; type = "stdio"; description = "Noctalia Firefox theme host";
            path = "/run/current-system/sw/bin/noctalia"; allowed_extensions = [ "pywalfox@frewacom.org" ];
          }))
        ];
      };
    })
  ];
}
