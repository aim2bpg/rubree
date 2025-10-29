// dropdown_orchestrator: manages the lifecycle of a header dropdown: opening,
// closing, outside click handling, reposition subscriptions and key handlers.
// The controller passes minimal dependencies (elements and callbacks).

export function createDropdownOrchestrator({
  dropdownEl,
  caretEl,
  onPosition,
  onClose,
}) {
  let _outsideClickHandler = null;
  let _repositionHandler = null;
  let _boundEsc = null;

  function _addHandlers() {
    _outsideClickHandler = (ev) => {
      try {
        const target = ev.target;
        if (!caretEl.contains(target) && !dropdownEl.contains(target)) {
          if (typeof onClose === "function") onClose();
        }
      } catch (_e) {}
    };
    document.addEventListener("click", _outsideClickHandler, true);

    _repositionHandler = () => {
      try {
        if (typeof onPosition === "function") onPosition();
      } catch (_e) {}
    };
    window.addEventListener("resize", _repositionHandler);
    window.addEventListener("scroll", _repositionHandler, true);

    _boundEsc = (ev) => {
      if (ev.key === "Escape") {
        if (typeof onClose === "function") onClose();
      }
    };
    document.addEventListener("keydown", _boundEsc);
  }

  function _removeHandlers() {
    try {
      if (_outsideClickHandler)
        document.removeEventListener("click", _outsideClickHandler, true);
    } catch (_e) {}
    try {
      if (_repositionHandler) {
        window.removeEventListener("resize", _repositionHandler);
        window.removeEventListener("scroll", _repositionHandler, true);
      }
    } catch (_e) {}
    try {
      if (_boundEsc) document.removeEventListener("keydown", _boundEsc);
    } catch (_e) {}
    _outsideClickHandler = null;
    _repositionHandler = null;
    _boundEsc = null;
  }

  function open() {
    try {
      if (!dropdownEl) return;
      // ensure visible
      dropdownEl.classList.remove("hidden");
      // initial positioning
      if (typeof onPosition === "function") onPosition();
      // add handlers
      _addHandlers();
    } catch (_e) {}
  }

  function close() {
    try {
      if (!dropdownEl) return;
      dropdownEl.classList.add("hidden");
      _removeHandlers();
    } catch (_e) {}
  }

  function dispose() {
    _removeHandlers();
  }

  return { open, close, dispose };
}
