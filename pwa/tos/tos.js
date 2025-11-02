// Event names (duplicated here to avoid a central dependency)
const SHOW_TOS = "rubree:show-tos";
const TOS_AGREED = "rubree:tos-agreed";

document.addEventListener("DOMContentLoaded", () => {
  const launchBtn = document.getElementById("launch-button");
  let modal = document.getElementById("tos-modal");

  let agreeBtn = null;
  let cancelBtn = null;
  let loaded = !!modal;

  function showModal() {
    if (!modal) return;
    modal.setAttribute("aria-hidden", "false");
    modal.style.display = "block";
    agreeBtn?.focus();
  }

  function hideModal() {
    if (!modal) return;
    modal.setAttribute("aria-hidden", "true");
    modal.style.display = "none";
  }

  function attachHandlers() {
    agreeBtn = document.getElementById("tos-agree");
    cancelBtn = document.getElementById("tos-cancel");

    agreeBtn?.addEventListener("click", function () {
      hideModal();
      window.dispatchEvent(new CustomEvent(TOS_AGREED));
    });

    cancelBtn?.addEventListener("click", function () {
      hideModal();
      launchBtn?.focus();
    });

    window.addEventListener(SHOW_TOS, function () {
      showModal();
    });

    launchBtn?.addEventListener("click", function () {
      showModal();
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && modal && modal.getAttribute("aria-hidden") === "false") {
        hideModal();
        launchBtn?.focus();
      }
    });
  }

  function loadTosIfNeeded() {
    return new Promise((resolve) => {
      if (loaded) { attachHandlers(); return resolve(); }

      const container = document.getElementById("tos-container") || document.body;
      fetch("./tos/tos.html").then((res) => {
        if (!res.ok) throw new Error("Failed to fetch tos.html");
        return res.text();
      }).then((html) => {
        container.insertAdjacentHTML("beforeend", html);
        modal = document.getElementById("tos-modal");
        loaded = true;
        attachHandlers();
        resolve();
      }).catch((err) => {
        console.warn("Could not load tos.html:", err);
        resolve();
      });
    });
  }

  loadTosIfNeeded().then(() => {
    if (modal) hideModal();
  });
});
