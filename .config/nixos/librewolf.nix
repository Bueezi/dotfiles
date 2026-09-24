# LibreWolf with my settings baked in. Replaces `librewolf` everywhere (via an overlay),
# so the plain `librewolf` in the main package list gets these changes.
#
# Prefs are set as *defaults*: they override LibreWolf's own defaults, but anything you
# change in Settings still sticks.
{ ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      librewolf = prev.librewolf.override {
        extraPrefs = ''
          // Fingerprinting protection off (fixes wrong timezone, light theme, captchas...)
          defaultPref("privacy.resistFingerprinting", false);
          // Bookmarks toolbar: never show
          defaultPref("browser.toolbars.bookmarks.visibility", "never");
          // Firefox Sync
          defaultPref("identity.fxaccounts.enabled", true);
          // Settings > Passwords: "Ask to save passwords" + "Save and autofill usernames and passwords"
          defaultPref("signon.rememberSignons", true);
          defaultPref("signon.autofillForms", true);
        '';

        extraPolicies.SearchEngines = {
          # LibreWolf's built-in DuckDuckGo is noai.duckduckgo.com; use the regular one
          Add = [{
            Name = "DuckDuckGo";
            URLTemplate = "https://duckduckgo.com/?q={searchTerms}";
            IconURL = "https://duckduckgo.com/favicon.ico";
            Alias = "@ddg";
          }];
          Default = "DuckDuckGo";
          Remove = [ "DuckDuckGo No-AI" ];
        };
      };
    })
  ];
}
