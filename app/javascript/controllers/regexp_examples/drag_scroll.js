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
    // dynamic axis detection: null until user moves ('horizontal'|'vertical')
    axis: null,
    startX: 0,
    startY: 0,
    startScrollLeft: 0,
    startScrollTop: 0,
    previousTouchAction: null,
    previousCursor: null,
  };

  try {
    // remember previous touch-action so we can restore on disable
    state.previousTouchAction = el.style.touchAction || "";
    // disable native panning so we can decide axis dynamically
    el.style.touchAction = "none";
    // set grab cursor so users see draggable affordance
    try {
      state.previousCursor = el.style.cursor || "";
      el.style.cursor = "grab";
    } catch (_e) {}
  } catch (_e) {}

  const pointerDown = (e) => {
    if (e.button && e.button !== 0) return;
    state.active = false;
    state.axis = null;
    state.pointerId = e.pointerId;
    state.startX = e.clientX;
    state.startY = e.clientY;
    try {
      state.startScrollLeft = el.scrollLeft;
      state.startScrollTop = el.scrollTop;
    } catch (_e) {
      state.startScrollLeft = 0;
      state.startScrollTop = 0;
    }
  };

  const pointerMove = (e) => {
    if (e.pointerId !== state.pointerId) return;
    const threshold = 6;
    const dx = e.clientX - state.startX;
    const dy = e.clientY - state.startY;

    // decide axis on first meaningful movement
    if (!state.axis) {
      if (Math.abs(dx) < threshold && Math.abs(dy) < threshold) return;
      state.axis = Math.abs(dx) > Math.abs(dy) ? "horizontal" : "vertical";
      state.active = true;
      try {
        el.setPointerCapture(e.pointerId);
      } catch (_e) {}
      el.classList.add("select-none");
      try {
        el.style.cursor = "grabbing";
      } catch (_e) {}
    }

    if (state.axis === "horizontal") {
      el.scrollLeft = state.startScrollLeft - dx;
    } else {
      el.scrollTop = state.startScrollTop - dy;
    }
    e.preventDefault();
  };

  const pointerUp = (_e) => {
    try {
      if (state.pointerId != null) el.releasePointerCapture(state.pointerId);
    } catch (_e) {}
    state.active = false;
    state.pointerId = null;
    state.axis = null;
    el.classList.remove("select-none");
    try {
      el.style.cursor = state.previousCursor || "";
    } catch (_e) {}
  };

  // capture pointerdown so we get the start even when initiated on child elements
  el.addEventListener("pointerdown", pointerDown, {
    passive: false,
    capture: true,
  });
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
        el.removeEventListener("pointerdown", pointerDown, {
          passive: false,
          capture: true,
        });
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
      try {
        // restore touch-action
        el.style.touchAction = state.previousTouchAction || "";
      } catch (_e) {}
      try {
        el.style.cursor = state.previousCursor || "";
      } catch (_e) {}
    },
    getScrollTop() {
      try {
        // prefer vertical scroll position by default; callers that care about horizontal can query element directly
        return el.scrollTop;
      } catch (_e) {
        return 0;
      }
    },
  };
}
