export function attachDropdownLifecycle({
  dropdownEl,
  caretEl,
  onClose,
  onReposition,
}) {
  if (!dropdownEl || !caretEl) return { detach() {} };

  const outsideClick = (ev) => {
    try {
      const target = ev.target;
      if (!caretEl.contains(target) && !dropdownEl.contains(target)) {
        onClose?.();
      }
    } catch (_e) {}
  };

  const repositionHandler = () => {
    try {
      onReposition?.();
    } catch (_e) {}
  };

  const keyHandler = (ev) => {
    try {
      if (ev.key === "Escape") onClose?.();
    } catch (_e) {}
  };

  document.addEventListener("click", outsideClick, true);
  window.addEventListener("resize", repositionHandler);
  window.addEventListener("scroll", repositionHandler, true);
  document.addEventListener("keydown", keyHandler);

  return {
    detach() {
      try {
        document.removeEventListener("click", outsideClick, true);
      } catch (_e) {}
      try {
        window.removeEventListener("resize", repositionHandler);
      } catch (_e) {}
      try {
        window.removeEventListener("scroll", repositionHandler, true);
      } catch (_e) {}
      try {
        document.removeEventListener("keydown", keyHandler);
      } catch (_e) {}
    },
  };
}
