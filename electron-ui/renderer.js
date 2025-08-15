// Setze Target-Dropdown-Werte nach Laden der Seite
function setTargetDropdownValues() {
  const hostedZoneDomain = window.electronAPI.getHostedZoneDomain();
  document.getElementById('targetOpt1').textContent = `www.${hostedZoneDomain}`;
  document.getElementById('targetOpt2').textContent = `${hostedZoneDomain}`;
}

window.addEventListener('hostedZoneDomainReady', setTargetDropdownValues);
setTargetDropdownValues();
document.getElementById('recordForm').addEventListener('submit', async function(e) {
  e.preventDefault();
  const form = e.target;
  const args = [
    form.CUSTOMER_DNS.value,
    form.MULTILINGUAL_OPTION.value,
    form.VARIANT_OPTION.value,
    form.TARGET_OPTION.value
  ];
  console.log('[CREATE RECORD] Args:', args);
  console.log('[CREATE RECORD] HOSTED_ZONE_DOMAIN:', window.electronAPI.getHostedZoneDomain());
  document.getElementById('output').textContent = 'Running...';
  try {
    const result = await window.electronAPI.runScript(args);
    document.getElementById('output').textContent = result;
  } catch (err) {
    document.getElementById('output').textContent = 'Error: ' + err;
  }
});

// Live Preview
const form = document.getElementById('recordForm');
const previewRecordName = document.getElementById('previewRecordName');
const previewMultilingual = document.getElementById('previewMultilingual');
const previewVariant = document.getElementById('previewVariant');
const previewTarget = document.getElementById('previewTarget');

function updatePreview() {
  // Bash-Logik für R53_RECORD_NAME
  const customerDns = form.CUSTOMER_DNS.value.trim();
  let subdomain = '', domain = '', tld = '';
  if (customerDns) {
    const parts = customerDns.split('.');
    subdomain = parts[0] || '';
    domain = parts[1] || '';
    tld = parts.slice(2).join('.') || '';
  }
  let multilingual = form.MULTILINGUAL_OPTION.value === '2' ? 'yes' : 'no';
  let variant = '';
  if (multilingual === 'yes') {
    variant = form.VARIANT_OPTION.value === '1' ? 'multilanguage-standard' : '';
  } else {
    variant = form.VARIANT_OPTION.value === '1' ? 'standard' : 'staging';
  }
  let recordNameTld = (tld === 'co.uk') ? 'uk' : tld;
  let r53RecordName = '';
  if (variant === 'standard') {
    if (subdomain.startsWith('cms')) {
      r53RecordName = `cms.production.${domain}`;
    } else if (subdomain.startsWith('rms')) {
      r53RecordName = `rms.production.${domain}`;
    } else if (subdomain.startsWith('preview')) {
      r53RecordName = `web.preview.${domain}`;
    } else {
      r53RecordName = `web.production.${domain}`;
    }
  } else if (variant === 'staging') {
    if (subdomain.startsWith('cms')) {
      r53RecordName = `cms.staging.${domain}`;
    } else if (subdomain.startsWith('rms')) {

    // Target-Wert aus .env berechnen
    let option1 = `www.${hostedZoneDomain}`;
    let option2 = `${hostedZoneDomain}`;
    let targetValue = form.TARGET_OPTION.value === '1' ? option1 : option2;
      r53RecordName = `rms.staging.${domain}`;
    } else if (subdomain.startsWith('preview')) {
      r53RecordName = `preview.staging.${domain}`;
    } else {
    previewTarget.textContent = targetValue;
    }
  } else if (variant === 'multilanguage-standard') {
    if (subdomain.startsWith('cms')) {
      r53RecordName = `cms.${recordNameTld}.production.${domain}`;
    } else if (subdomain.startsWith('rms')) {
      r53RecordName = `rms.${recordNameTld}.production.${domain}`;
    } else if (subdomain.startsWith('preview')) {
      r53RecordName = '(Multilingual preview not supported)';
    } else {
      r53RecordName = `web.${recordNameTld}.production.${domain}`;
    }
  }
  // Punkt am Ende, falls nicht vorhanden
  if (r53RecordName && !r53RecordName.endsWith('.')) {
    r53RecordName += '.';
  }
  // HOSTED_ZONE_DOMAIN aus window
  const hostedZoneDomain = window.electronAPI.getHostedZoneDomain();
  if (r53RecordName && !r53RecordName.includes('(Multilingual preview')) {
    r53RecordName = `${r53RecordName}${hostedZoneDomain}.`;
  }
  previewRecordName.textContent = r53RecordName;
  previewMultilingual.textContent = form.MULTILINGUAL_OPTION.options[form.MULTILINGUAL_OPTION.selectedIndex].text;
  previewVariant.textContent = form.VARIANT_OPTION.options[form.VARIANT_OPTION.selectedIndex].text;
  previewTarget.textContent = form.TARGET_OPTION.options[form.TARGET_OPTION.selectedIndex].text;
}

form.CUSTOMER_DNS.addEventListener('input', updatePreview);
form.MULTILINGUAL_OPTION.addEventListener('change', updatePreview);
form.VARIANT_OPTION.addEventListener('change', updatePreview);
form.TARGET_OPTION.addEventListener('change', updatePreview);

updatePreview();

// Aktualisiere Preview, wenn HOSTED_ZONE_DOMAIN gesetzt wurde
window.addEventListener('hostedZoneDomainReady', updatePreview);

  window.addEventListener('hostedZoneDomainReady', () => {
    console.log('[RENDERER] HOSTED_ZONE_DOMAIN:', window.electronAPI.getHostedZoneDomain());
  });

// Test-Button für HOSTED_ZONE_DOMAIN
document.getElementById('testDomainBtn').addEventListener('click', function() {
    const val = window.electronAPI.getHostedZoneDomain();
    document.getElementById('testDomainOutput').textContent = 'HOSTED_ZONE_DOMAIN: ' + val;
});
