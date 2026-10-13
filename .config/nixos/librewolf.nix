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
          // Settings > Search: "Show search suggestions" (also in the address bar)
          defaultPref("browser.search.suggest.enabled", true);
          defaultPref("browser.urlbar.suggest.searches", true);
          // No "Restore Session" crash page after powering off with it open
          // (History > Restore Previous Session still brings the old tabs back)
          defaultPref("browser.sessionstore.resume_from_crash", false);

          // Rice: vertical tabs always shown, compact density (the colours: the Dark space theme
          // below). The sidebar ones are pref(), not defaultPref(): they were changed in Settings
          // before, and saved user values would win over defaults
          pref("sidebar.revamp", true);
          pref("sidebar.verticalTabs", true);
          pref("sidebar.visibility", "always-show");
          defaultPref("browser.compactmode.show", true);
          defaultPref("browser.uidensity", 1);
          // Home / new tab: no search box (the address bar searches anyway). Forced, and kept
          // out of Firefox Sync: a machine on an older config synced `true` back to the others
          pref("browser.newtabpage.activity-stream.showSearch", false);
          pref("services.sync.prefs.sync.browser.newtabpage.activity-stream.showSearch", false);
          // Closing the last tab leaves an empty new tab instead of closing the window
          defaultPref("browser.tabs.closeWindowWithLastTab", false);
        '';

        # "Dark space" theme: black with animated stars (enable it once in Add-ons → Themes)
        extraPolicies.ExtensionSettings."{22b0eca1-8c02-4c0d-a5d7-6604ddd9836e}" = {
          installation_mode = "normal_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/nicothin-space/latest.xpi";
        };

        extraPolicies.SearchEngines = {
          # LibreWolf's built-in DuckDuckGo is noai.duckduckgo.com; use the regular one
          Add = [{
            Name = "DuckDuckGo";
            URLTemplate = "https://duckduckgo.com/?q={searchTerms}";
            # Without this the engine offers no suggestions, whatever the settings say
            SuggestURLTemplate = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
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
