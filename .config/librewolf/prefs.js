// defaultPref(): Settings can still change it; pref(): forced
// No backticks or dollar signs: the Nix wrapper runs this file through the shell

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

// Settings' own custom new tab wallpaper still draws over the one below
Components.classes["@mozilla.org/observer-service;1"].getService(Components.interfaces.nsIObserverService)
  .addObserver({ observe() {
    const Cc = Components.classes, Ci = Components.interfaces;
    const sss = Cc["@mozilla.org/content/style-sheet-service;1"].getService(Ci.nsIStyleSheetService);
    const addCss = css => sss.loadAndRegisterSheet(Cc["@mozilla.org/network/io-service;1"]
      .getService(Ci.nsIIOService).newURI("data:text/css," + encodeURIComponent(css)), sss.USER_SHEET);
    // No buttons under the vertical tabs (not sidebar.main.tools = "": refilled at startup), and the
    // collapsed sidebar takes its width from them. No close button: inTitlebar 0 would turn the toolbar grey
    addCss('@-moz-document url("chrome://browser/content/browser.xhtml") { ' +
      'sidebar-main:not([expanded]) { min-width: var(--tab-collapsed-width) !important; } ' +
      '#sidebar-tools-and-extensions-splitter, .buttons-wrapper, .titlebar-buttonbox-container { display: none !important; } }');
    // New tab background: the wallpaper ~/.cache/noctalia/wallpaper links to (Noctalia's wallpaper_changed
    // hook), checked every 10 s. A data: URL: the new tab page's sandbox can't read ~
    Components.utils.importGlobalProperties(["btoa"]);
    let shown = "", sheet = null;
    const update = () => { try {
      const link = Cc["@mozilla.org/file/directory_service;1"].getService(Ci.nsIProperties).get("Home", Ci.nsIFile);
      for (const p of [".cache", "noctalia", "wallpaper"]) link.append(p);
      if (!link.exists() || link.target === shown) return;
      const f = Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile);
      f.initWithPath(link.target);
      const fs = Cc["@mozilla.org/network/file-input-stream;1"].createInstance(Ci.nsIFileInputStream);
      fs.init(f, -1, 0, 0);
      const bs = Cc["@mozilla.org/binaryinputstream;1"].createInstance(Ci.nsIBinaryInputStream);
      bs.setInputStream(fs);
      const img = btoa(bs.readBytes(bs.available()));
      fs.close();
      const type = { png: "png", webp: "webp", gif: "gif" }[f.leafName.split(".").pop().toLowerCase()] || "jpeg";
      const uri = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService).newURI("data:text/css," +
        encodeURIComponent('@-moz-document url("about:newtab"), url("about:home") { body { background: ' +
          'url("data:image/' + type + ';base64,' + img + '") center / cover fixed !important; } }'));
      sss.loadAndRegisterSheet(uri, sss.USER_SHEET);
      if (sheet) sss.unregisterSheet(sheet, sss.USER_SHEET);
      sheet = uri; shown = f.path;
    } catch (e) { Components.utils.reportError(e); } };
    update();
    this.timer = Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer);
    this.timer.initWithCallback(update, 10000, Ci.nsITimer.TYPE_REPEATING_SLACK);
  } }, "final-ui-startup");

defaultPref("browser.fireButton.enabled", false);   // flame "Forget" button, on in LibreWolf 160
// Toolbar (Customize → Restore Defaults, then restart: until then it shows Firefox's own). "seen": else uBlock/SponsorBlock pin themselves
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
