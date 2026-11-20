const { app, BrowserWindow } = require('electron');
const path = require('path');
const fs = require('fs');
const expressApp = require('./server/app');
const { autoUpdater } = require('electron-updater');

const logFile = path.join(__dirname, 'switchbot-debug.log');

function log(step, extra) {
  const detail = extra === undefined ? '' : (typeof extra === 'string' ? extra : JSON.stringify(extra));
  const line = new Date().toISOString() + ' ' + step + (detail ? ' ' + detail : '');
  console.log(line);
  try {
    fs.appendFileSync(logFile, line + '\n');
  } catch (err) {
    console.error('Could not write debug log', err.message);
  }
}

// Linux: a frameless window plus Wayland leaves a grey window even with
// --disable-gpu. Force software rendering, and X11 when this is a Wayland session.
if (process.platform === 'linux') {
  app.disableHardwareAcceleration();
  app.commandLine.appendSwitch('disable-gpu');
  app.commandLine.appendSwitch('disable-gpu-compositing');
  const sessionType = process.env.XDG_SESSION_TYPE || '';
  const onWayland = sessionType === 'wayland' || !!process.env.WAYLAND_DISPLAY;
  if (onWayland && !process.env.SWITCHBOT_OZONE) {
    app.commandLine.appendSwitch('ozone-platform', 'x11');
    log('ozone', 'forcing x11 because session is wayland');
  }
}

let mainWindow;

function esc(s) {
  return String(s)
    .replace(/&/g, '&' + 'amp;')
    .replace(/</g, '&' + 'lt;')
    .replace(/>/g, '&' + 'gt;');
}

function showLoadError(reason) {
  const html = `<!doctype html><html><body style="margin:0;background:#111924;color:#fff;font-family:sans-serif">
    <div style="padding:32px;max-width:720px">
      <h1>SwitchBot could not show the page</h1>
      <p>${esc(reason)}</p>
      <p>Debug log: ${esc(logFile)}</p>
    </div>
  </body></html>`;
  mainWindow.loadURL('data:text/html;charset=utf-8,' + encodeURIComponent(html));
}

function createWindow() {
  const indexHtml = path.join(__dirname, 'client', 'build', 'index.html');
  const linux = process.platform === 'linux';
  log('start', {
    platform: process.platform,
    electron: process.versions.electron,
    session: process.env.XDG_SESSION_TYPE || '',
    display: process.env.DISPLAY || '',
    wayland: process.env.WAYLAND_DISPLAY || '',
    index: indexHtml,
    indexExists: fs.existsSync(indexHtml)
  });

  const options = {
    width: 1280,
    height: 720,
    show: false,
    backgroundColor: '#111924',
    title: 'SwitchBot App',
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
    },
  };
  const iconPath = path.join(__dirname, 'client/build', 'switchbot.ico');
  if (fs.existsSync(iconPath)) options.icon = iconPath;

  // titleBarOverlay on Linux draws the buttons and leaves the page blank.
  if (!linux) {
    options.frame = false;
    options.titleBarStyle = 'hidden';
    options.titleBarOverlay = {
      color: '#111924',
      symbolColor: '#fff',
      height: 32
    };
  }

  mainWindow = new BrowserWindow(options);

  mainWindow.webContents.on('did-fail-load', (_event, code, description, url) => {
    log('did-fail-load', { code, description, url });
    showLoadError('Load failed ' + code + ' ' + description + ' ' + url);
    mainWindow.show();
  });
  mainWindow.webContents.on('did-finish-load', () => {
    log('did-finish-load', mainWindow.webContents.getURL());
  });
  mainWindow.webContents.on('render-process-gone', (_event, details) => {
    log('render-process-gone', details);
  });
  mainWindow.webContents.on('console-message', (_event, level, message, line, sourceId) => {
    log('renderer', { level, message, line, sourceId });
  });
  mainWindow.webContents.on('preload-error', (_event, preloadPath, error) => {
    log('preload-error', { preloadPath, message: error && error.message });
  });
  mainWindow.once('ready-to-show', () => {
    log('ready-to-show');
    mainWindow.show();
  });
  setTimeout(() => {
    if (mainWindow && !mainWindow.isDestroyed() && !mainWindow.isVisible()) {
      log('force-show', 'ready-to-show did not fire');
      mainWindow.show();
    }
  }, 4000);

  if (!fs.existsSync(indexHtml)) {
    showLoadError('Client build is missing: ' + indexHtml);
  } else {
    mainWindow.loadFile(indexHtml);
  }

  if (process.env.SWITCHBOT_DEBUG === '1') {
    mainWindow.webContents.openDevTools({ mode: 'detach' });
  }
}

autoUpdater.autoDownload = false;

autoUpdater.on('update-available', () => {
  if (mainWindow) mainWindow.webContents.send('update-message', 'Update available. Downloading...');
  autoUpdater.downloadUpdate();
});

autoUpdater.on('update-downloaded', () => {
  if (mainWindow) mainWindow.webContents.send('update-message', 'Update downloaded. It will be installed on restart.');
});

autoUpdater.on('error', (err) => {
  log('updater', err == null ? 'unknown' : err.message);
});

process.on('uncaughtException', (err) => {
  log('uncaughtException', err && err.stack ? err.stack : String(err));
});

app.whenReady().then(() => {
  log('debug-log', logFile);
  createWindow();
  mainWindow.webContents.once('did-finish-load', () => {
    mainWindow.webContents.send('update-message', 'Checking for updates...');
    autoUpdater.checkForUpdates().catch((err) => {
      log('checkForUpdates', err && err.message ? err.message : String(err));
    });
  });
});

expressApp.listen(8089, () => {
  log('server', 'http://localhost:8089');
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
