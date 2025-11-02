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
