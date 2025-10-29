// drag_scroll: provides pointer-based drag-to-scroll for a scrollable container.
// Returns an object with `disable()` and `getScrollTop()` methods.
export function enableDragScroll(el, initialScroll = 0) {
  if (!el)
    return {
      disable() {},
      getScrollTop() {
        return 0;
      },
    };

  try {
    if (typeof initialScroll === "number") el.scrollTop = initialScroll || 0;
  } catch (_e) {}

  const state = {
    active: false,
    pointerId: null,
    startY: 0,
    startScroll: 0,
  };

  const pointerDown = (e) => {
    if (e.button && e.button !== 0) return;
    state.active = false;
    state.pointerId = e.pointerId;
    state.startY = e.clientY;
    state.startScroll = el.scrollTop;
  };

  const pointerMove = (e) => {
    if (e.pointerId !== state.pointerId) return;
    const dy = e.clientY - state.startY;
    const threshold = 6;
    if (!state.active) {
      if (Math.abs(dy) < threshold) return;
      state.active = true;
      try {
        el.setPointerCapture(e.pointerId);
      } catch (_e) {}
      el.classList.add("select-none");
    }
    el.scrollTop = state.startScroll - dy;
    e.preventDefault();
  };

  const pointerUp = (_e) => {
    try {
      if (state.pointerId != null) el.releasePointerCapture(state.pointerId);
    } catch (_e) {}
    state.active = false;
    state.pointerId = null;
    el.classList.remove("select-none");
  };

  el.addEventListener("pointerdown", pointerDown, { passive: false });
  el.addEventListener("pointermove", pointerMove, { passive: false });
  el.addEventListener("pointerup", pointerUp);
  el.addEventListener("pointercancel", pointerUp);

  const scrollHandler = () => {
    // no-op here; controller may query getScrollTop
  };
  el.addEventListener("scroll", scrollHandler, { passive: true });

  return {
    disable() {
      try {
        el.removeEventListener("pointerdown", pointerDown, { passive: false });
      } catch (_e) {}
      try {
        el.removeEventListener("pointermove", pointerMove, { passive: false });
      } catch (_e) {}
      try {
        el.removeEventListener("pointerup", pointerUp);
        el.removeEventListener("pointercancel", pointerUp);
      } catch (_e) {}
      try {
        el.removeEventListener("scroll", scrollHandler, { passive: true });
      } catch (_e) {}
      el.classList.remove("select-none");
    },
    getScrollTop() {
      try {
        return el.scrollTop;
      } catch (_e) {
        return 0;
      }
    },
  };
}
