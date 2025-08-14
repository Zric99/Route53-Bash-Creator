
const { contextBridge, ipcRenderer } = require('electron');

let hostedZoneDomain = 'example.com';
ipcRenderer.on('hostedZoneDomain', (event, value) => {
  hostedZoneDomain = value;
  window.HOSTED_ZONE_DOMAIN = value;
  console.log('[PRELOAD] HOSTED_ZONE_DOMAIN set:', value);
  window.dispatchEvent(new Event('hostedZoneDomainReady'));
});

let hostedZoneDomainValue = 'example.com';
ipcRenderer.on('hostedZoneDomain', (event, value) => {
  hostedZoneDomainValue = value;
  console.log('[PRELOAD] HOSTED_ZONE_DOMAIN set:', value);
  window.dispatchEvent(new Event('hostedZoneDomainReady'));
});

contextBridge.exposeInMainWorld('electronAPI', {
  runScript: (args) => ipcRenderer.invoke('run-script', args),
  getHostedZoneDomain: () => hostedZoneDomainValue
});
