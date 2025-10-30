import { trapFocus as sharedTrapFocus } from "./trap_focus";

// Minimal modal orchestrator: handles show/hide animation and focus trap.
// Controllers should manage content insertion and keyboard handlers.
export function showModal(modalEl) {
  if (!modalEl) return () => {};
  try {
    modalEl.classList.remove("hidden");
    modalEl.classList.remove("opacity-0");
    modalEl.classList.add("opacity-100");
  } catch (_e) {}
  let removeFocus = null;
  try {
    removeFocus = sharedTrapFocus(modalEl);
  } catch (_e) {
    removeFocus = () => {};
  }
  return removeFocus;
}

export function hideModal(
  modalEl,
  { clearContentEl = null, duration = 220, removeFocus = null } = {},
) {
  if (!modalEl) return;
  try {
    modalEl.classList.remove("opacity-100");
    modalEl.classList.add("opacity-0");
  } catch (_e) {}

  try {
    if (typeof removeFocus === "function") removeFocus();
  } catch (_e) {}

  setTimeout(() => {
    try {
      modalEl.classList.add("hidden");
      if (clearContentEl) clearContentEl.innerHTML = "";
    } catch (_e) {}
  }, duration);
}
