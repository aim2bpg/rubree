async function registerServiceWorker() {
  const ua = navigator.userAgent;
  const isFirefox = ua.includes("Firefox");
  const isSafari = /^((?!chrome|android).)*safari/i.test(ua);
  
  const oldRegistrations = await navigator.serviceWorker.getRegistrations();
  for (const registration of oldRegistrations) {
    if (registration.installing?.state === "installing") {
      return;
    }
  }

  const workerUrl =
    import.meta.env.MODE === "production"
      ? "./rails.sw.js"
      : "./dev-sw.js?dev-sw";

  // Try module registration first
  try {
    await navigator.serviceWorker.register(workerUrl, {
      scope: import.meta.env.BASE_URL,
      type: "module",
    });
    return;
  } catch (error) {
    // Show warning banner for Safari/Firefox
    if (isSafari || isFirefox) {
      try {
        const warningEl = document.getElementById("browser-warning");
        const detectedBrowserEl = document.getElementById("detected-browser");
        if (warningEl) {
          warningEl.classList.remove("hidden");
        }
        if (detectedBrowserEl) {
          const browserName = isFirefox ? "Firefox" : "Safari";
          detectedBrowserEl.textContent = browserName;
        }
      } catch (e) {}
    }
    
    // Try classic as fallback
    try {
      await navigator.serviceWorker.register(workerUrl, {
        scope: import.meta.env.BASE_URL,
        type: "classic",
      });
      return;
    } catch (classicError) {
      // Re-throw a simple error to avoid Safari stack overflow on complex error objects
      const errorMsg = classicError && classicError.message ? String(classicError.message) : "Service Worker registration failed";
      throw new Error(errorMsg);
    }
  }
}

async function boot({ bootProgress, bootConsoleOutput }) {
  if (!("serviceWorker" in navigator)) {
    console.error("Service Worker is not supported in this browser.");
    return;
  }

  if (!navigator.serviceWorker.controller) {
    await registerServiceWorker();
  } else {
    console.log("Service Worker already active.");
  }

  navigator.serviceWorker.addEventListener("message", function (event) {
    switch (event.data.type) {
      case "progress": {
        if (bootProgress) bootProgress.value = event.data.value;
        break;
      }
      case "console": {
        // Guard in case the output element is not present (avoid uncaught TypeError)
        if (bootConsoleOutput) {
          bootConsoleOutput.textContent += event.data.message + "\n";
        }
        break;
      }
      default: {
        console.log("Unknown message type:", event.data.type);
      }
    }
  });

  return await navigator.serviceWorker.ready;
}

async function init() {
  // Detect browser first
  const ua = navigator.userAgent;
  const isFirefox = ua.includes("Firefox");
  const isSafari = /^((?!chrome|android).)*safari/i.test(ua);
  const browserName = isFirefox ? "Firefox" : isSafari ? "Safari" : "Other";
  
  // Show warning banner immediately for Safari/Firefox
  if (isSafari || isFirefox) {
    console.warn("[boot] Unsupported browser detected: " + browserName);
    try {
      const warningEl = document.getElementById("browser-warning");
      const detectedBrowserEl = document.getElementById("detected-browser");
      if (warningEl) {
        warningEl.classList.remove("hidden");
      }
      if (detectedBrowserEl) {
        detectedBrowserEl.textContent = browserName;
      }
    } catch (e) {}
    
    // Disable the launch button
    const launchButton = document.getElementById("launch-button");
    if (launchButton) {
      launchButton.disabled = true;
      launchButton.style.opacity = "0.5";
      launchButton.style.cursor = "not-allowed";
    }
    return; // Don't set up event listeners
  }
  
  // removed automatic boot flow; init will now wait for user action
  const launchButton = document.getElementById("launch-button");

  // SW numeric progress handler removed per user request; keep seconds-only UI.

  // Stay one step before starting: do not register the service worker or load the app
  // automatically on page load. Let the user click Start -> agree TOS -> then we
  // register the SW and open the app. This prevents reloads from showing the already-
  // started app unexpectedly.

  if (launchButton) launchButton.disabled = false;

  // When user clicks Start, show the TOS modal (tos.js will dispatch 'rubree:tos-agreed' on agree)
  launchButton.addEventListener("click", function () {
    window.dispatchEvent(new CustomEvent('rubree:show-tos'));
  });

  // After user agrees, perform safe registration and then open the app in a new window.
  window.addEventListener('rubree:tos-agreed', async function() {
    // Seamless same-tab start: show overlay + spinner, register SW, then navigate
    if (launchButton) launchButton.disabled = true;

    // Show the full-screen starting overlay for a smooth transition
    const overlay = document.getElementById('starting-overlay');
    // Choose overlay mode: 'timer' shows a count-up seconds; 'bar' shows a filling progress bar.
    // Set to 'bar' to enable the second-by-second bar visualization.
    const START_OVERLAY_MODE = 'bar'; // 'timer' | 'bar'

    // timerEl used for 'timer' mode; secondsEl used for bar mode display next to bar.
    const timerEl = document.getElementById('starting-timer') || document.getElementById('starting-seconds');
    const secondsEl = document.getElementById('starting-seconds');
    const barEl = document.getElementById('starting-bar');
    const barFill = document.getElementById('starting-bar-fill');

    let _startTimerId = null;
    let _startTs = null;

    const startElapsedTimer = () => {
      if (timerEl) timerEl.textContent = '0s';
      _startTs = Date.now();
      _startTimerId = setInterval(() => {
        const elapsed = Math.floor((Date.now() - _startTs) / 1000);
        if (timerEl) timerEl.textContent = `${elapsed}s`;
      }, 1000);
    };

    const stopElapsedTimer = () => {
      if (_startTimerId) {
        clearInterval(_startTimerId);
        _startTimerId = null;
      }
      if (timerEl) timerEl.textContent = '';
    };

    // bar mode: discrete 1s ticks over a nominal BAR_SECONDS window; caps at 99% until ready
    const BAR_SECONDS = 10; // restored to default

    const startBar = () => {
      if (!barEl) return;
      // create segments if not already present
      barEl.innerHTML = '';
      for (let i = 0; i < BAR_SECONDS; i++) {
        const seg = document.createElement('div');
        seg.className = 'starting-bar-seg';
        // plain tick segments (no emojis) — styling will mark active segments
        // set a small flex-basis so gaps remain visible; flex will size evenly
        barEl.appendChild(seg);
      }
      barEl.style.display = 'flex';
      if (timerEl) timerEl.textContent = '';
      if (secondsEl) secondsEl.textContent = '0s';
      _startTs = Date.now();
      let elapsed = 0;
      _startTimerId = setInterval(() => {
        elapsed += 1;
        const idx = elapsed - 1; // 0-based
        const segs = barEl.querySelectorAll('.starting-bar-seg');
        if (segs[idx]) segs[idx].classList.add('active');
        // cap the bar at BAR_SECONDS but keep the seconds counter running
        if (elapsed <= BAR_SECONDS) {
          if (secondsEl) secondsEl.textContent = `${elapsed}s`;
        } else {
          // after the nominal BAR_SECONDS window show a human-friendly hint
          if (secondsEl) secondsEl.textContent = 'Soon';
        }
      }, 1000);
    };

    const stopBar = (complete = false) => {
      if (_startTimerId) {
        clearInterval(_startTimerId);
        _startTimerId = null;
      }
      if (barEl) {
        // simple hide; keep current filled segments as-is (no extra emphasis)
        // hide after brief delay so 100% can be perceived
        setTimeout(() => {
          if (barEl) barEl.style.display = 'none';
          const wrap = document.getElementById('starting-bar-wrap');
          if (wrap) wrap.style.display = 'none';
        }, 220);
      }
      if (secondsEl) secondsEl.textContent = '';
    };

    if (overlay) overlay.classList.add('show');
    if (START_OVERLAY_MODE === 'bar') {
      // show wrapper
      const wrap = document.getElementById('starting-bar-wrap');
      if (wrap) wrap.style.display = 'flex';
      startBar();
    } else {
      // ensure spinner visible in timer mode
      startElapsedTimer();
    }

    const startingTextEl = document.getElementById('starting-text');

    try {
      await registerServiceWorker();
      const registration = await navigator.serviceWorker.ready;

      // Send a start-rails message to the service worker and wait for reply.
      const controller = navigator.serviceWorker.controller || registration.active;
      if (controller) {
        const msgChannel = new MessageChannel();
        const reply = new Promise((resolve) => {
          msgChannel.port1.onmessage = (e) => {
            const data = e.data || {};
            if (data.type === 'rails-started') resolve({ ok: true });
            else if (data.type === 'rails-start-failed') {
              resolve({ ok: false, error: data.error });
            }
          };
        });

        // send port to SW so it can reply directly
        controller.postMessage({ type: 'start-rails' }, [msgChannel.port2]);

        const res = await Promise.race([reply, new Promise((r) => setTimeout(() => r({ ok: false, timeout: true }), 30000))]);
        if (!res.ok) {
          throw new Error(res.error || (res.timeout ? 'timeout waiting for SW' : 'unknown'));
        }
      } else {
        // No active controller — still continue and let SW init happen later.
        console.warn('No active service worker controller to start rails');
      }

      // Small delay so the overlay fade-in can be perceived as smooth
      await new Promise((r) => setTimeout(r, 260));
      // Ensure the visual bar runs for at least BAR_SECONDS seconds to avoid
      // showing the completion message too early if the Service Worker becomes
      // ready quickly. Calculate remaining time (if any) and wait for it.
      const minDisplayMs = BAR_SECONDS * 1000;
      const elapsedMs = _startTs ? (Date.now() - _startTs) : 0;
      const remainingMs = Math.max(0, minDisplayMs - elapsedMs);
      if (remainingMs > 0) {
        await new Promise((r) => setTimeout(r, remainingMs));
      }

      // stop indicator immediately before navigating
      if (typeof stopBar === 'function') stopBar(true);
      stopElapsedTimer();
      // show a short welcome message so the user sees completion before navigating
      if (startingTextEl) {
        // bilingual short welcome to match the TOS tone
        startingTextEl.textContent = '🎉 Welcome to Rubree 🎉';
        // add a temporary class so we can enlarge it visually
        startingTextEl.classList.add('welcome');
      }
      // brief pause so the welcome message is perceivable (~1s)
      await new Promise((r) => setTimeout(r, 1000));

      // Navigate the current window to the app root (same-tab navigation)
      window.location.href = './';
    } catch (e) {
      // Safari-safe error logging: completely avoid touching the error object if possible
      let errorMsg = "Unknown error occurred";
      let errorName = "Error";
      
      try {
        if (e && typeof e.message === "string") {
          errorMsg = e.message;
        }
        if (e && typeof e.name === "string") {
          errorName = e.name;
        }
      } catch (accessError) {
        // Even accessing error properties can fail in Safari - use fallback
        errorMsg = "Error details unavailable (Safari limitation)";
      }
      
      // Safari-safe logging: avoid any string concatenation with error objects
      try {
        console.error('Failed to register service worker or start app:', errorName, '-', errorMsg);
      } catch (logError) {
        // Even logging can fail in Safari with certain error objects
        console.error('Failed to register service worker or start app (details unavailable)');
      }
      
      if (overlay) {
        try {
          overlay.classList.remove('show');
        } catch (ignore) {}
      }
      // ensure welcome styling is cleaned up on failure
      if (startingTextEl) startingTextEl.classList.remove('welcome');
      // stop the elapsed timer or bar on failure
      if (typeof stopBar === 'function') stopBar(false);
      stopElapsedTimer();
      // cleanup
      if (launchButton) launchButton.disabled = false;
    }
  });

}

init();
