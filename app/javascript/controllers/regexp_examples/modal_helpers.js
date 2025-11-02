import { trapFocus as sharedTrapFocus } from "../lib/trap_focus";

export function trapFocus(modal) {
  try {
    return sharedTrapFocus(modal);
  } catch (_e) {
    return () => {};
  }
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
