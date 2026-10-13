// LibreWolf prefs for every machine. NixOS: librewolf.nix bakes this file into the package. The
// tablet (Termux): termux.sh links it as ~/.librewolf/librewolf.overrides.cfg. Policies (theme,
// search engine) are in policies.json next to this file.
// defaultPref() overrides LibreWolf's defaults, but what you change in Settings still sticks;
// pref() forces the value.

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

// Rice: vertical tabs always shown, compact density (the colours: the Dark space theme in
// policies.json). The sidebar ones are pref(), not defaultPref(): they were changed in Settings
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
