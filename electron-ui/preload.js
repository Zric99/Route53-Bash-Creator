const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  runScript: (args) => ipcRenderer.invoke('run-script', args)
});
