// modal_helpers: trap focus and manage a small result observer used by modal.
export function trapFocus(modal) {
  if (!modal) return () => {};
  const focusable = modal.querySelectorAll(
    'a[href], button:not([disabled]), textarea, input, select, [tabindex]:not([tabindex="-1"])',
  );
  if (!focusable.length) return () => {};
  const first = focusable[0];
  const last = focusable[focusable.length - 1];
  try {
    first.focus();
  } catch (_e) {}
  const handler = (e) => {
    if (e.key !== "Tab") return;
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  };
  modal.addEventListener("keydown", handler);
  return () => {
    try {
      modal.removeEventListener("keydown", handler);
    } catch (_e) {}
  };
}

export function createResultObserver(modalTarget, modalResultTarget) {
  let observer = null;

  function update() {
    if (!modalResultTarget) return;
    const frame = document.getElementById("regexp");
    if (!frame) return;
    const clone = frame.cloneNode(true);
    const ts = Date.now();
    clone.querySelectorAll("[id]").forEach((el) => {
      const old = el.getAttribute("id");
      if (old) el.setAttribute("id", `${old}-modal-${ts}`);
    });
    clone.id = `${clone.id || "regexp"}-modal-${ts}`;
    modalResultTarget.innerHTML = "";
    modalResultTarget.appendChild(clone);
  }

  function start() {
    const frame = document.getElementById("regexp");
    if (!frame) return;
    observer = new MutationObserver(() => {
      if (!modalTarget.classList.contains("hidden")) update();
    });
    observer.observe(frame, { childList: true, subtree: true });
  }

  function stop() {
    if (observer) {
      observer.disconnect();
      observer = null;
    }
  }

  return { start, stop, update };
}
