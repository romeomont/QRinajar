const { contextBridge, shell, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("splashAPI", {
  openExternal: (url) => shell.openExternal(url),
  setDontShowAgain: (checked) => ipcRenderer.send("splash-dont-show-again", checked),
  onVersion: (callback) => ipcRenderer.on("app-version", (_event, version) => callback(version)),
});
