const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { execFile } = require('child_process');
const fs = require('fs');
const dotenv = require('dotenv');

// .env auslesen
let hostedZoneDomain = 'example.com';
try {
  const envPath = path.join(__dirname, '../.env');
  if (fs.existsSync(envPath)) {
    const envConfig = dotenv.parse(fs.readFileSync(envPath));
    if (envConfig.HOSTED_ZONE_DOMAIN) {
      hostedZoneDomain = envConfig.HOSTED_ZONE_DOMAIN.replace(/"/g, '');
      console.log('[DEBUG] HOSTED_ZONE_DOMAIN loaded from .env:', hostedZoneDomain);
    } else {
      console.log('[DEBUG] HOSTED_ZONE_DOMAIN not found in .env, fallback to example.com');
    }
  }
} catch (e) {}

function createWindow() {
  const win = new BrowserWindow({
    width: 700,
    height: 800,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true
  // Übergabe per IPC/contextBridge
    }
  });
  win.loadFile('index.html');

    // Sende HOSTED_ZONE_DOMAIN nach Renderer
    win.webContents.on('did-finish-load', () => {
      win.webContents.send('hostedZoneDomain', hostedZoneDomain);
    });
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') app.quit();
});

ipcMain.handle('run-script', async (event, args) => {
  return new Promise((resolve, reject) => {
    execFile(path.join(__dirname, '../create_record.sh'), args, { env: process.env }, (error, stdout, stderr) => {
      if (error) {
        resolve(stderr || error.message);
      } else {
        resolve(stdout);
      }
    });
  });
});
