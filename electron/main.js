const { app, BrowserWindow, Menu, ipcMain } = require("electron");
const path = require("path");
const fs = require("fs");

const SPLASH_DURATION_MS = 4000;
const PREF_FILE = path.join(app.getPath("userData"), "splash-pref.json");

let dontShowAgainChoice = false;

function readSplashPref() {
  try {
    return JSON.parse(fs.readFileSync(PREF_FILE, "utf8"));
  } catch {
    return null; // no file yet = first launch
  }
}

function writeSplashPref(dontShowSplash) {
  try {
    fs.mkdirSync(path.dirname(PREF_FILE), { recursive: true });
    fs.writeFileSync(PREF_FILE, JSON.stringify({ dontShowSplash }));
  } catch {
    // non-fatal: worst case the splash just shows again next launch
  }
}

function createMainWindow() {
  const win = new BrowserWindow({
    width: 1100,
    height: 800,
    icon: path.join(__dirname, "icon.ico"),
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  Menu.setApplicationMenu(null);
  win.loadFile(path.join(__dirname, "..", "dist", "qrinajar.html"));
  return win;
}

function createSplashWindow(onDone) {
  const splash = new BrowserWindow({
    width: 380,
    height: 340,
    frame: false,
    resizable: false,
    center: true,
    icon: path.join(__dirname, "icon.ico"),
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      preload: path.join(__dirname, "preload-splash.js"),
    },
  });

  splash.loadFile(path.join(__dirname, "splash.html"));
  splash.webContents.once("did-finish-load", () => {
    splash.webContents.send("app-version", app.getVersion());
  });

  const timer = setTimeout(() => {
    writeSplashPref(dontShowAgainChoice);
    if (!splash.isDestroyed()) splash.close();
    onDone();
  }, SPLASH_DURATION_MS);

  splash.on("closed", () => clearTimeout(timer));
}

ipcMain.on("splash-dont-show-again", (_event, checked) => {
  dontShowAgainChoice = checked;
});

app.whenReady().then(() => {
  const pref = readSplashPref();
  const skipSplash = pref != null && pref.dontShowSplash === true;

  if (skipSplash) {
    createMainWindow();
  } else {
    createSplashWindow(() => createMainWindow());
  }

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createMainWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
