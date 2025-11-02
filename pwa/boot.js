// Event constants (duplicated here to keep pwa files self-contained)
const SHOW_TOS = "rubree:show-tos";
const TOS_AGREED = "rubree:tos-agreed";

async function registerServiceWorker() {
  if (!("serviceWorker" in navigator)) return;

  const oldRegistrations = await navigator.serviceWorker.getRegistrations();
  for (const registration of oldRegistrations) {
    if (registration.installing && registration.installing.state === "installing") {
      return;
    }
  }

  const workerUrl =
    import.meta.env.MODE === "production"
      ? "./rails.sw.js"
      : "./dev-sw.js?dev-sw";

  await navigator.serviceWorker.register(workerUrl, {
    scope: import.meta.env.BASE_URL,
    type: "module",
  });
}

// Inlined overlay helper (moved from pwa/lib/overlay.js)
let _timerId = null;

function _el(id) { return document.getElementById(id); }

function startOverlay(mode = "timer") {
  const overlay = _el("starting-overlay");
  const barWrap = _el("starting-bar-wrap");
  const barEl = _el("starting-bar");
  const secondsEl = _el("starting-seconds");

  if (overlay) overlay.classList.add("show");

  if (mode === "bar") {
    if (barWrap) barWrap.style.display = "flex";
    if (barEl) {
      barEl.innerHTML = "";
      const BAR_SECONDS = 10;
      for (let i = 0; i < BAR_SECONDS; i++) {
        const seg = document.createElement("div");
        seg.className = "starting-bar-seg";
        barEl.appendChild(seg);
      }
      barEl.style.display = "flex";
    }

    let elapsed = 0;
    if (secondsEl) secondsEl.textContent = "0s";
    _timerId = setInterval(() => {
      elapsed += 1;
      const segs = barEl ? barEl.querySelectorAll(".starting-bar-seg") : [];
      const idx = elapsed - 1;
      if (segs[idx]) {
        segs[idx].classList.add("active", "bg-gradient-to-r", "from-sky-500", "to-blue-600", "shadow-md", "-translate-y-1");
      }
      if (secondsEl) secondsEl.textContent = elapsed <= 10 ? `${elapsed}s` : "Soon";
    }, 1000);
  } else {
    let _startTs = Date.now();
    if (secondsEl) secondsEl.textContent = "0s";
    _timerId = setInterval(() => {
      const elapsed = Math.floor((Date.now() - _startTs) / 1000);
      if (secondsEl) secondsEl.textContent = `${elapsed}s`;
    }, 1000);
  }
}

function stopOverlay(complete = false) {
  if (_timerId) {
    clearInterval(_timerId);
    _timerId = null;
  }

  const barEl = _el("starting-bar");
  const wrap = _el("starting-bar-wrap");
  const secondsEl = _el("starting-seconds");
  const overlay = _el("starting-overlay");
  const startingTextEl = _el("starting-text");

  if (barEl) {
    setTimeout(() => {
      if (barEl) barEl.style.display = "none";
      if (wrap) wrap.style.display = "none";
    }, 220);
  }

  if (secondsEl) secondsEl.textContent = "";

  if (overlay) overlay.classList.remove("show");

  if (startingTextEl) {
    if (complete) {
      startingTextEl.textContent = "🎉 Welcome to Rubree 🎉";
      startingTextEl.classList.add("welcome");
    } else {
      startingTextEl.classList.remove("welcome");
    }
  }
}

async function init() {
  const bootMessage = document.getElementById("boot-message");
  const launchButton = document.getElementById("launch-button");

  if (bootMessage) bootMessage.textContent = "";
  if (launchButton) launchButton.disabled = false;

  launchButton.addEventListener("click", function () {
    try {
      window.dispatchEvent(new CustomEvent(SHOW_TOS));
    } catch (e) {
      console.warn(`${SHOW_TOS} dispatch failed, falling back to DOM toggle`, e);
    }

    const modal = document.getElementById("tos-modal");
    if (modal && modal.getAttribute && modal.getAttribute("aria-hidden") === "true") {
      modal.setAttribute("aria-hidden", "false");
      modal.classList.remove("hidden");
      modal.classList.add("flex");
      const agree = document.getElementById("tos-agree");
      if (agree && typeof agree.focus === "function") agree.focus();
    }
  });

  window.addEventListener(TOS_AGREED, async function () {
    if (launchButton) launchButton.disabled = true;
    if (bootMessage) bootMessage.textContent = "Initializing...";

  const START_OVERLAY_MODE = "bar";
    // show overlay (handles bar/timer internally)
    startOverlay(START_OVERLAY_MODE);

    try {
      await registerServiceWorker();
  if (bootMessage) bootMessage.textContent = "Starting Rubree...";
      await navigator.serviceWorker.ready;

      await new Promise((r) => setTimeout(r, 260));

      // stop overlay and show welcome state
      stopOverlay(true);
      await new Promise((r) => setTimeout(r, 1000));

      window.location.href = "./";
    } catch (e) {
      console.error("Failed to register service worker or start app:", e);
  if (bootMessage) bootMessage.textContent = "Failed to start — please try again.";
  stopOverlay(false);
      if (launchButton) launchButton.disabled = false;
    }
  });
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", init);
} else {
  init();
}
