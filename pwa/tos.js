// Externalized TOS modal logic for pwa/index.html
document.addEventListener('DOMContentLoaded', () => {
  const launchBtn = document.getElementById('launch-button');
  const modal = document.getElementById('tos-modal');

  let agreeBtn = null;
  let cancelBtn = null;

  function showModal(){
    if (!modal) return;
    modal.setAttribute('aria-hidden','false');
    modal.style.display = 'block';
    if (agreeBtn) agreeBtn.focus();
  }

  function hideModal(){
    if (!modal) return;
    modal.setAttribute('aria-hidden','true');
    modal.style.display = 'none';
  }

  function startApp(){
    window.open('./', '_blank');
  }

  // Load modal HTML from tos.html then wire up handlers
  async function loadTos(){
    if (!modal) return;
    try {
      const res = await fetch('./tos.html');
      if (!res.ok) throw new Error('Failed to load tos.html');
      const html = await res.text();
      modal.innerHTML = html;

      // now elements exist
      agreeBtn = document.getElementById('tos-agree');
      cancelBtn = document.getElementById('tos-cancel');

      agreeBtn?.addEventListener('click', function(){
        hideModal();
        // Notify the page that TOS was agreed; boot.js will perform registration
        // and then navigate the current window to the app, with a smooth overlay.
        window.dispatchEvent(new CustomEvent('rubree:tos-agreed'));
      });

      cancelBtn?.addEventListener('click', function(){
        hideModal();
        launchBtn?.focus();
      });
    } catch (e) {
      console.warn('Could not load tos.html', e);
    }
  }

  // When service worker requests to show TOS
  window.addEventListener('rubree:show-tos', function(){
    showModal();
  });

  // Show TOS when launch clicked
  launchBtn?.addEventListener('click', function(){
    showModal();
  });

  document.addEventListener('keydown', function(e){
    if(e.key === 'Escape' && modal && modal.getAttribute('aria-hidden') === 'false'){
      hideModal();
      launchBtn?.focus();
    }
  });

  // initialize
  loadTos().then(()=>{
    // ensure hidden after load
    hideModal();
  });
});
