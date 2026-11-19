// defaultPref(): Settings can still change it; pref(): forced

// Fingerprinting protection off (fixes wrong timezone, light theme, captchas...)
defaultPref("privacy.resistFingerprinting", false);
defaultPref("browser.toolbars.bookmarks.visibility", "never");
defaultPref("identity.fxaccounts.enabled", true);
// The old look, not the "Nova" redesign (on by default in LibreWolf 158)
defaultPref("browser.nova.enabled", false);
defaultPref("signon.rememberSignons", true);
defaultPref("signon.autofillForms", true);
defaultPref("browser.search.suggest.enabled", true);
defaultPref("browser.urlbar.suggest.searches", true);
defaultPref("browser.sessionstore.resume_from_crash", false);

// pref(): saved user values from before would win over defaults
pref("sidebar.revamp", true);
pref("sidebar.verticalTabs", true);
pref("sidebar.visibility", "always-show");
defaultPref("browser.compactmode.show", true);
defaultPref("browser.uidensity", 1);
// Locked and kept out of Sync: else it got reset while running
lockPref("browser.newtabpage.activity-stream.showSearch", false);
pref("services.sync.prefs.sync.browser.newtabpage.activity-stream.showSearch", false);
defaultPref("browser.tabs.closeWindowWithLastTab", false);
defaultPref("browser.download.useDownloadDir", true);   // LibreWolf asks every time
