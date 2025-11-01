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

  // Wire up handlers for the inlined TOS modal (we keep this simple because
  // tos.html is now inlined into index.html and should not be fetched at runtime)
  function loadTos(){
    if (!modal) return;
    agreeBtn = document.getElementById('tos-agree');
    cancelBtn = document.getElementById('tos-cancel');

    // attach handlers if buttons exist
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
