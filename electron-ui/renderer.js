document.getElementById('recordForm').addEventListener('submit', async function(e) {
  e.preventDefault();
  const form = e.target;
  const args = [
    form.CUSTOMER_DNS.value,
    form.MULTILINGUAL_OPTION.value,
    form.VARIANT_OPTION.value,
    form.TARGET_OPTION.value
  ];
  document.getElementById('output').textContent = 'Running...';
  try {
    const result = await window.electronAPI.runScript(args);
    document.getElementById('output').textContent = result;
  } catch (err) {
    document.getElementById('output').textContent = 'Error: ' + err;
  }
});
