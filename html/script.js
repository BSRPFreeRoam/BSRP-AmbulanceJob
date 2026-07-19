const death = document.getElementById('death');
let maxTime = 300;

window.addEventListener('message', (e) => {
  const msg = e.data || {};
  if (msg.action === 'death') {
    const d = msg.data || {};
    death.classList.remove('hidden');
    document.getElementById('dMode').textContent = d.mode === 'laststand' ? 'CRITICAL' : 'OFFLINE';
    document.getElementById('dTitle').textContent = d.title || 'VITALS';
    document.getElementById('dLine1').textContent = d.line1 || '';
    document.getElementById('dLine2').textContent = d.line2 || '';
    if (d.time != null) {
      if (d.time > maxTime) maxTime = d.time;
      const pct = Math.max(0, Math.min(100, (d.time / maxTime) * 100));
      document.getElementById('dFill').style.width = pct + '%';
    }
  }
  if (msg.action === 'hideDeath') {
    death.classList.add('hidden');
    maxTime = 300;
  }
});
