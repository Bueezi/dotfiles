// Eclipse Music (https://eclipsemusic.app/web/) as a desktop app: one window and a tray icon.
// Closing the window only hides it (music keeps playing); quit from the tray menu.
// Launching it again (app menu, $mod+m) shows/hides the running window.
const { app, BrowserWindow, Menu, Tray, shell } = require("electron");
const path = require("path");

const START_URL = "https://eclipsemusic.app/web/";
const icon = path.join(__dirname, "icon.png");

let win, tray;
let quitting = false;

if (!app.requestSingleInstanceLock()) {
  app.quit();   // already running: that instance gets "second-instance" and toggles
} else {
  app.on("second-instance", toggle);
  app.on("before-quit", () => { quitting = true; });
  app.whenReady().then(() => {
    createWindow();
    createTray();
  });
}

function createWindow() {
  win = new BrowserWindow({
    title: "Eclipse",
    icon,
    width: 1100,
    height: 750,
    backgroundColor: "#09090B",
    autoHideMenuBar: true,
  });
  win.removeMenu();
  win.loadURL(START_URL);

  // Eclipse pages (and sign-in popups) stay in the app, other links open in the browser
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (new URL(url).hostname.endsWith("eclipsemusic.app")) return { action: "allow" };
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
  tray.setToolTip("Eclipse");
  tray.setContextMenu(Menu.buildFromTemplate([
    { label: "Show / Hide", click: toggle },
    { type: "separator" },
    { label: "Quit Eclipse", click: () => app.quit() },
  ]));
  tray.on("click", toggle);
}

function toggle() {
  if (win.isVisible() && win.isFocused()) {
    win.hide();
  } else {
    win.show();
    win.focus();
  }
}
