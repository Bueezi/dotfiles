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

defaultPref("browser.tabs.inTitlebar", 0);   // no close button
// Toolbar (Customize → Restore Defaults comes back here). "seen": else uBlock/SponsorBlock pin themselves
defaultPref("browser.uiCustomization.state", JSON.stringify({
  placements: {
    "nav-bar": ["back-button", "forward-button", "customizableui-special-spring1", "vertical-spacer",
      "stop-reload-button", "urlbar-container", "logins-button", "customizableui-special-spring2",
      "downloads-button", "reset-pbm-toolbar-button", "unified-extensions-button",
      "addon_darkreader_org-browser-action", "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action"],
    "unified-extensions-area": ["ublock0_raymondhill_net-browser-action", "sponsorblocker_ajay_app-browser-action"],
    "widget-overflow-fixed-list": [],
    "toolbar-menubar": ["menubar-items"],
    "TabsToolbar": [],
    "vertical-tabs": ["tabbrowser-tabs"],
    "PersonalToolbar": ["personal-bookmarks"],
  },
  seen: ["ublock0_raymondhill_net-browser-action", "sponsorblocker_ajay_app-browser-action",
    "addon_darkreader_org-browser-action", "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action"],
  dirtyAreaCache: ["nav-bar", "TabsToolbar", "vertical-tabs", "toolbar-menubar", "PersonalToolbar", "unified-extensions-area"],
  currentVersion: 28,
  newElementCount: 2,
}));
