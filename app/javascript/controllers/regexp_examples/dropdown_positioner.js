export function positionHeaderDropdown(el, caret) {
  if (!el || !caret) return;
  try {
    const rect = caret.getBoundingClientRect();
    const smallScreen = window.innerWidth < 640; // Tailwind 'sm' breakpoint
    el.style.position = "absolute";
    if (smallScreen) {
      const pagePadding = 12;
      const maxWidth = Math.min(420, window.innerWidth - pagePadding * 2);
      const width = Math.max(260, maxWidth);
      const tentativeLeft = rect.right + window.scrollX - width;
      const minLeft = window.scrollX + pagePadding;
      const maxLeft = window.scrollX + window.innerWidth - pagePadding - width;
      const left = Math.min(Math.max(tentativeLeft, minLeft), maxLeft);
      const top = rect.bottom + window.scrollY + 6;
      el.style.left = `${left}px`;
      el.style.top = `${top}px`;
      el.style.width = `${width}px`;
    } else {
      const ddWidth = el.offsetWidth || 280;
      let left = rect.right + window.scrollX - ddWidth;
      const top = rect.bottom + window.scrollY + 6;
      const minLeft = window.scrollX + 8;
      const maxRight = window.scrollX + window.innerWidth - 8;
      if (left < minLeft) left = minLeft;
      if (left + ddWidth > maxRight)
        left = Math.max(minLeft, maxRight - ddWidth);
      el.style.left = `${left}px`;
      el.style.top = `${top}px`;
      el.style.width = "";
    }
  } catch (_e) {
    // swallow — positioning is best-effort
  }
}
