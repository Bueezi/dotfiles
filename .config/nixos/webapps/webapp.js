// A web page as a desktop app: one window and a tray icon. Closing the window only hides it (music
// keeps playing); quit from the tray menu. Launching it again (app menu, its key) shows/hides the
// running window. Each app is a folder next to this file (package.json, icon.png, index.js with its
// page); NixOS: ../webapps.nix, the tablet: .config/termux/bin/webapp.
const { app, BrowserWindow, Menu, Tray, shell } = require("electron");
const fs = require("fs");
const net = require("net");
const path = require("path");

module.exports = ({ dir, title, url, domains, background }) => {
  const icon = path.join(dir, "icon.png");
  // Pages on these domains (and sign-in popups) stay in the app, other links open in the browser
  const inApp = (link) => {
    const host = new URL(link).hostname;
    return domains.some((d) => host === d || host.endsWith("." + d));
  };
  let win, tray;
  let quitting = false;
  // Plain Chrome's user agent (without "<app>/<version>" and "Electron/…"): Google refuses to sign
  // in from Electron
  app.userAgentFallback = app.userAgentFallback
    .replace(/(like Gecko\)).*?(?= Chrome\/)/, "$1")
    .replace(/ Electron\/\S+/, "");

  // Already running? Its socket answers: it toggles, this one quits. Not Electron's
  // requestSingleInstanceLock: on the tablet (Termux) that let every launch open another window
  const sock = path.join(app.getPath("userData"), "toggle.sock");
  const client = net.connect(sock, () => { client.end(); app.quit(); });
  client.on("error", () => {
    fs.mkdirSync(path.dirname(sock), { recursive: true });
    fs.rmSync(sock, { force: true });   // left over from a crash
    // A socket it can't make (path too long, …) only costs the check, not the app
    net.createServer((s) => { s.end(); toggle(); }).on("error", () => {}).listen(sock);
    app.on("before-quit", () => { quitting = true; });
    app.whenReady().then(() => {
      createWindow();
      createTray();
    });
  });

  function createWindow() {
    win = new BrowserWindow({
      title,
      icon,
      width: 1100,
      height: 750,
      backgroundColor: background,
      autoHideMenuBar: true,
    });
    win.removeMenu();
    win.loadURL(url);

    win.webContents.setWindowOpenHandler(({ url }) => {
      if (inApp(url)) return { action: "allow" };
      shell.openExternal(url);
      return { action: "deny" };
    });

    win.on("close", (e) => {
      if (quitting) return;
      e.preventDefault();
      win.hide();
    });
  }

  function createTray() {
    tray = new Tray(icon);
    tray.setToolTip(title);
    tray.setContextMenu(Menu.buildFromTemplate([
      { label: "Show / Hide", click: toggle },
      { type: "separator" },
      { label: `Quit ${title}`, click: () => app.quit() },
    ]));
    tray.on("click", toggle);
  }

  function toggle() {
    if (!win) return;   // a second launch before this one's window exists
    if (win.isVisible() && win.isFocused()) {
      win.hide();
    } else {
      win.show();
      win.focus();
    }
  }
};
