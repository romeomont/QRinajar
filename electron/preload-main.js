const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("windowAPI", {
  minimize: () => ipcRenderer.send("window-minimize"),
  toggleMaximize: () => ipcRenderer.send("window-toggle-maximize"),
  close: () => ipcRenderer.send("window-close"),
  onMaximizedChange: (callback) =>
    ipcRenderer.on("window-maximized-change", (_event, isMaximized) => callback(isMaximized)),
});
