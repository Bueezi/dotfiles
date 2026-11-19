// A web page as a tray app: close hides, launching again toggles. Per app: `block` URLs, `preload` script
const { app, BrowserWindow, Menu, Tray, session, shell } = require("electron");
const fs = require("fs");
const net = require("net");
const path = require("path");

module.exports = ({ dir, title, url, domains, background, block, preload }) => {
  const icon = path.join(dir, "icon.png");
  // Pages on these domains (and sign-in popups) stay in the app, other links open in the browser
  const inApp = (link) => {
    const host = new URL(link).hostname;
    return domains.some((d) => host === d || host.endsWith("." + d));
  };
  let win, tray;
  let quitting = false;

  const sock = path.join(app.getPath("userData"), "toggle.sock");
  const client = net.connect(sock, () => { client.end(); app.quit(); });
  client.on("error", () => {
    fs.mkdirSync(path.dirname(sock), { recursive: true });
    fs.rmSync(sock, { force: true });   // left over from a crash
    net.createServer((s) => { s.end(); toggle(); }).on("error", () => {}).listen(sock);
    app.on("before-quit", () => { quitting = true; });
    app.whenReady().then(() => {
      if (block) {
        session.defaultSession.webRequest.onBeforeRequest({ urls: block }, (_, done) => done({ cancel: true }));
      }
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
      webPreferences: preload ? { preload: path.join(dir, preload) } : {},
    });
    win.removeMenu();
    win.loadURL(url);

    win.webContents.setWindowOpenHandler(({ url }) => {
      if (inApp(url)) return { action: "allow" };
      shell.openExternal(url);
      return { action: "deny" };
    });

    // beforeunload would silently cancel Quit
    win.webContents.on("will-prevent-unload", (e) => e.preventDefault());

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
