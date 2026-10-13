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
// Home / new tab: no search box (the address bar searches anyway). Locked: with pref() something
// (Sync, the new tab's own settings) reset it while running and the box came back. Also kept
// out of Firefox Sync: a machine on an older config synced `true` back to the others
lockPref("browser.newtabpage.activity-stream.showSearch", false);
pref("services.sync.prefs.sync.browser.newtabpage.activity-stream.showSearch", false);
// Closing the last tab leaves an empty new tab instead of closing the window
defaultPref("browser.tabs.closeWindowWithLastTab", false);

// Toolbar layout, the same everywhere (copied from the desktop's Customize Toolbar): sidebar, back,
// forward, reload | address bar, passwords | downloads, extensions, Vimium, Dark Reader and the
// other pinned extensions. Forced at every start: change it here, not in Customize Toolbar (or
// customise, then copy browser.uiCustomization.state from about:config into this)
pref("browser.uiCustomization.state", JSON.stringify({
    placements: {
        "nav-bar": [
            "sidebar-button",
            "back-button",
            "forward-button",
            "stop-reload-button",
            "customizableui-special-spring1",
            "vertical-spacer",
            "urlbar-container",
            "logins-button",
            "customizableui-special-spring2",
            "downloads-button",
            "reset-pbm-toolbar-button",
            "unified-extensions-button",
            "dearrow_ajay_app-browser-action",
            "_7c7f6dea-3957-4bb9-9eec-2ef2b9e5bcec_-browser-action",
            "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action",
            "jid1-qofqdk4qzufgwq_jetpack-browser-action",
            "addon_darkreader_org-browser-action",
            "smartwindow-group-tabs-button",
            "ai-window-toggle"
        ],
        "vertical-tabs": [
            "tabbrowser-tabs"
        ],
        "TabsToolbar": [],
        "unified-extensions-area": [
            "sponsorblocker_ajay_app-browser-action",
            "ublock0_raymondhill_net-browser-action",
            "claude_usage_tracker_lugia19_com-browser-action",
            "_88ebde3a-4581-4c6b-8019-2a05a9e3e938_-browser-action",
            "_react-devtools-browser-action",
            "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action",
            "_9a3104a2-02c2-464c-b069-82344e5ed4ec_-browser-action",
            "amazineurope_founderedeveloper_com-browser-action",
            "_e58d3966-3d76-4cd9-8552-1582fbc800c1_-browser-action",
            "idcac-pub_guus_ninja-browser-action",
            "gdpr_cavi_au_dk-browser-action",
            "firefoxpwa_filips_si-browser-action"
        ],
        "widget-overflow-fixed-list": [],
        "toolbar-menubar": [
            "menubar-items"
        ],
        "PersonalToolbar": [
            "personal-bookmarks"
        ]
    },
    seen: ["reset-pbm-toolbar-button", "developer-button", "screenshot-button", "ublock0_raymondhill_net-browser-action", "claude_usage_tracker_lugia19_com-browser-action", "_88ebde3a-4581-4c6b-8019-2a05a9e3e938_-browser-action", "_react-devtools-browser-action", "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action", "addon_darkreader_org-browser-action", "_9a3104a2-02c2-464c-b069-82344e5ed4ec_-browser-action", "amazineurope_founderedeveloper_com-browser-action", "_e58d3966-3d76-4cd9-8552-1582fbc800c1_-browser-action", "sponsorblocker_ajay_app-browser-action", "idcac-pub_guus_ninja-browser-action", "dearrow_ajay_app-browser-action", "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action", "gdpr_cavi_au_dk-browser-action", "firefoxpwa_filips_si-browser-action", "_7c7f6dea-3957-4bb9-9eec-2ef2b9e5bcec_-browser-action", "jid1-qofqdk4qzufgwq_jetpack-browser-action"],
    dirtyAreaCache: ["nav-bar", "TabsToolbar", "vertical-tabs", "toolbar-menubar", "PersonalToolbar", "unified-extensions-area"],
    currentVersion: 26,
    newElementCount: 10,
}));
