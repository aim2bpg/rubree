import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="regexp-examples"
export default class extends Controller {
  static targets = [
    "tab",
    "category",
    "example",
    "pattern",
    "test",
    "options",
    "substitution",
    "modal",
    "modalContent",
    "modalResult",
    "exampleSelect",
    "caretButton",
    "diceButton",
    "headerDropdown",
    "headerScroll",
    "hoverCategory",
    "filter",
    "root",
  ];

  connect() {
    // initialize tab selection
    if (this.hasTabTarget && this.tabTargets[0]) {
      this.showCategoryByElement(this.tabTargets[0]);
    }

    this._boundEsc = this._onEsc.bind(this);
    this._focusHandler = null;
    this._previousActive = null;
    this._observer = null;
    this._movedForm = null;

    // wire select change for all exampleSelect elements and choose a primary select (header if present)
    this._selectElements = Array.from(
      document.querySelectorAll(
        '[data-regexp-examples-target="exampleSelect"]',
      ),
    );
    this._selectHandler = this.selectFromSelect.bind(this);
    this._selectElements.forEach((sel) => {
      sel.addEventListener("change", this._selectHandler);
    });
    this._primarySelect =
      document.getElementById("examples-select-header") ||
      this._selectElements?.[0] ||
      null;

    // add focus/blur listeners to primary select so we can animate the caret
    this._primarySelectFocusHandler = () => this._setCaretOpen(true);
    this._primarySelectBlurHandler = () => this._setCaretOpen(false);
    if (this._primarySelect) {
      this._primarySelect.addEventListener(
        "focus",
        this._primarySelectFocusHandler,
      );
      this._primarySelect.addEventListener(
        "blur",
        this._primarySelectBlurHandler,
      );
    }
    this._diceTimeout = null;
    this._headerOpen = false;
    this._outsideClickHandler = null;
    this._dropdownKeyHandler = this._onDropdownKeydown.bind(this);
    this._repositionHandler = null;
  }

  disconnect() {
    // cleanup
    if (this._observer) this._observer.disconnect();
    document.removeEventListener("keydown", this._boundEsc);
    if (
      this._selectHandler &&
      this._selectElements &&
      this._selectElements.length
    ) {
      this._selectElements.forEach((sel) => {
        sel.removeEventListener("change", this._selectHandler);
      });
    }
    // remove primary select listeners
    try {
      if (this._primarySelect) {
        this._primarySelect.removeEventListener(
          "focus",
          this._primarySelectFocusHandler,
        );
        this._primarySelect.removeEventListener(
          "blur",
          this._primarySelectBlurHandler,
        );
      }
    } catch (_e) {}
    if (this._diceTimeout) {
      clearTimeout(this._diceTimeout);
      this._diceTimeout = null;
    }

    // remove header dropdown listeners if any
    try {
      if (this._outsideClickHandler)
        document.removeEventListener("click", this._outsideClickHandler, true);
      document.removeEventListener("keydown", this._boundHeaderEsc);
    } catch (_e) {}

    // restore moved form if still moved
    if (this._movedForm) this._restoreForm();
  }

  showCategory(event) {
    const tab = event.currentTarget;
    this.showCategoryByElement(tab);
  }

  showCategoryByElement(tab) {
    const selected = tab.dataset.category;

    this.tabTargets.forEach((t) => {
      t.classList.toggle("bg-gray-700", t === tab);
      t.classList.toggle("text-white", t === tab);
      t.classList.toggle("bg-gray-800", t !== tab);
      t.classList.toggle("text-gray-300", t !== tab);
    });

    this.categoryTargets.forEach((c) => {
      const match = c.dataset.category === selected;
      c.classList.toggle("hidden", !match);
    });
  }

  selectExample(event) {
    const { pattern, test, options, substitution } =
      event.currentTarget.dataset;

    const patternEl =
      document.querySelector("input#regular_expression_expression") ||
      this.patternTarget;
    const testEl =
      document.querySelector("textarea#regular_expression_test_string") ||
      this.testTarget;

    if (patternEl && testEl) {
      patternEl.value = pattern || "";
      testEl.value = test || "";

      // options/substitution if available
      if (this.hasOptionsTarget) this.optionsTarget.value = options || "";
      if (this.hasSubstitutionTarget)
        this.substitutionTarget.value = substitution || "";

      // dispatch input events so other controllers react
      patternEl.dispatchEvent(new Event("input", { bubbles: true }));
      testEl.dispatchEvent(new Event("input", { bubbles: true }));
      if (this.hasSubstitutionTarget)
        this.substitutionTarget.dispatchEvent(
          new Event("input", { bubbles: true }),
        );
    } else {
      console.warn("⚠️ Pattern or Test field not found");
    }
    // if header dropdown is open, close it after selection **only if** the
    // selection did NOT originate from inside the header dropdown itself.
    // This allows clicks inside the dropdown to keep it open as requested.
    try {
      if (this._headerOpen) {
        const fromHeaderDropdown =
          this.hasHeaderDropdownTarget &&
          this.headerDropdownTarget.contains(event.currentTarget);
        if (!fromHeaderDropdown) this._closeHeaderDropdown();
      }
    } catch (_e) {}
  }

  // open modal: move real form into modal and clone examples for readability
  openModal(event) {
    event?.preventDefault();
    if (!this.hasModalTarget || !this.hasModalContentTarget) return;

    // move actual form into modal to keep behavior consistent
    const mainForm = document.querySelector(
      'form[data-controller*="regexp-form"]',
    );
    if (mainForm && !this._movedForm) {
      this._movedForm = {
        el: mainForm,
        parent: mainForm.parentNode,
        nextSibling: mainForm.nextSibling,
      };
    }

    // clone examples block but avoid copying turbo frames
    const container = this.hasRootTarget ? this.rootTarget : this.element;
    const clone = container.cloneNode(true);
    clone.querySelectorAll('turbo-frame, [id="regexp"]').forEach((el) => {
      el.remove();
    });
    clone.querySelectorAll(".hidden").forEach((el) => {
      el.classList.remove("hidden");
    });

    // insert form (moved) and clone into modal
    this.modalContentTarget.innerHTML = "";
    if (this._movedForm)
      this.modalContentTarget.appendChild(this._movedForm.el);
    this.modalContentTarget.appendChild(clone);

    // show modal
    this.modalTarget.classList.remove("hidden");
    this._previousActive = document.activeElement;
    // focus select or modal
    if (this._primarySelect) this._primarySelect.focus();
    else this.modalTarget.focus();
    this.trapFocus(this.modalTarget);
    document.addEventListener("keydown", this._boundEsc);

    // start observing result frame for live updates
    this._startResultObserver();
    this._updateModalResult();
  }

  closeModal(event) {
    event?.preventDefault();
    if (!this.hasModalTarget || !this.hasModalContentTarget) return;

    this.modalTarget.classList.add("hidden");
    // restore moved form
    if (this._movedForm) this._restoreForm();
    this.modalContentTarget.innerHTML = "";
    if (this.hasModalResultTarget) this.modalResultTarget.innerHTML = "";
    try {
      if (this._previousActive) this._previousActive.focus();
    } catch (_e) {}
    document.removeEventListener("keydown", this._boundEsc);
    if (this._observer) {
      this._observer.disconnect();
      this._observer = null;
    }
  }

  _onEsc(e) {
    if (e.key === "Escape") this.closeModal();
  }

  // restore moved form back to original place
  _restoreForm() {
    try {
      const { el, parent, nextSibling } = this._movedForm;
      if (nextSibling) parent.insertBefore(el, nextSibling);
      else parent.appendChild(el);
    } catch (_e) {}
    this._movedForm = null;
  }

  // select from select element: use server-rendered index mapping
  selectFromSelect(e) {
    const value = e.target.value;
    const examples = Array.from(
      document.querySelectorAll('[data-regexp-examples-target="example"]'),
    );
    const idx = parseInt(value, 10);
    let target = null;
    if (!Number.isNaN(idx) && examples[idx]) target = examples[idx];
    if (target) {
      target.dispatchEvent(new Event("click", { bubbles: true }));
      // update modal result
      this._updateModalResult();
    }
  }

  nextExample(_event) {
    const sel = this._primarySelect || this._selectElements?.[0];
    if (!sel) return;
    const len = sel.options.length;
    if (!len) return;
    let idx = sel.selectedIndex;
    idx = (idx + 1) % len;
    sel.selectedIndex = idx;
    sel.dispatchEvent(new Event("change", { bubbles: true }));
  }

  prevExample(_event) {
    const sel = this._primarySelect || this._selectElements?.[0];
    if (!sel) return;
    const len = sel.options.length;
    if (!len) return;
    let idx = sel.selectedIndex;
    idx = (idx - 1 + len) % len;
    sel.selectedIndex = idx;
    sel.dispatchEvent(new Event("change", { bubbles: true }));
  }

  tryExample(_event) {
    // pick a random example and apply it on the primary select (header) if present
    const sel = this._primarySelect || this._selectElements?.[0];
    if (sel) {
      const len = sel.options.length;
      if (len) {
        const idx = Math.floor(Math.random() * len);
        sel.selectedIndex = idx;
        sel.dispatchEvent(new Event("change", { bubbles: true }));
      }
    } else {
      // fallback: no select present (we use custom dropdown). Pick a random example element.
      try {
        const examples = Array.from(
          document.querySelectorAll('[data-regexp-examples-target="example"]'),
        );
        if (examples.length) {
          const idx = Math.floor(Math.random() * examples.length);
          examples[idx].dispatchEvent(new Event("click", { bubbles: true }));
        }
      } catch (_e) {}
    }

    // animate dice button briefly if present
    try {
      if (this.hasDiceButtonTarget) {
        const el = this.diceButtonTarget;
        el.classList.add("animate-bounce");
        if (this._diceTimeout) clearTimeout(this._diceTimeout);
        this._diceTimeout = setTimeout(() => {
          el.classList.remove("animate-bounce");
          this._diceTimeout = null;
        }, 600);
      }
    } catch (_e) {}
  }

  focusPrimarySelect(e) {
    e?.preventDefault();
    const sel = this._primarySelect || this._selectElements?.[0];
    if (!sel) return;
    // try to open native picker if available, otherwise focus
    try {
      if (typeof sel.showPicker === "function") sel.showPicker();
    } catch (_err) {
      // ignore
    }
    try {
      sel.focus();
    } catch (_err) {}
    // ensure caret shows open state
    this._setCaretOpen(true);
  }

  // Toggle header dropdown (opened by caret button)
  toggleHeaderDropdown(e) {
    e?.preventDefault();
    if (!this.hasHeaderDropdownTarget) return;
    if (this._headerOpen) this._closeHeaderDropdown();
    else this._openHeaderDropdown();
  }

  _openHeaderDropdown() {
    try {
      let el = this.headerDropdownTarget;
      // If the dropdown is not attached to body, move it so we can absolutely position reliably
      if (el && el.parentElement !== document.body) {
        try {
          this._headerDropdownOriginal = {
            parent: el.parentElement,
            nextSibling: el.nextSibling,
          };
          document.body.appendChild(el);
        } catch (_e) {
          // fallback: ignore
        }
        // refresh reference
        el = this.headerDropdownTarget;
      }

      // ensure absolute positioning for moved dropdown
      if (el) {
        el.style.position = "absolute";
        el.style.left = "0px";
        el.style.top = "0px";
        // clear width so _positionHeaderDropdown can recalc (responsive)
        el.style.width = "";
      }
      // prepare animation start state
      el.classList.remove("hidden");
      el.classList.remove("opacity-100", "translate-y-0");
      el.classList.add("opacity-0", "translate-y-1");
      // force reflow then transition to visible
      // position before showing transition
      try {
        this._positionHeaderDropdown();
      } catch (_e) {}

      requestAnimationFrame(() => {
        el.classList.remove("opacity-0", "translate-y-1");
        el.classList.add(
          "opacity-100",
          "translate-y-0",
          "transition",
          "ease-out",
          "duration-150",
        );
      });
      this._setCaretOpen(true);
      this._headerOpen = true;

      // focus first interactive item in dropdown if available
      try {
        const first = this.headerDropdownTarget.querySelector("button");
        if (first) first.focus();
      } catch (_e) {}

      // enable drag-to-scroll on the internal scroll area (mouse/touch drag)
      try {
        this._enableDragScroll();
      } catch (_e) {}

      // close on outside click (clicks outside caret and dropdown)
      this._outsideClickHandler = (ev) => {
        try {
          const target = ev.target;
          if (
            this.hasCaretButtonTarget &&
            this.hasHeaderDropdownTarget &&
            !this.caretButtonTarget.contains(target) &&
            !this.headerDropdownTarget.contains(target)
          ) {
            this._closeHeaderDropdown();
          }
        } catch (_e) {}
      };
      document.addEventListener("click", this._outsideClickHandler, true);

      // add reposition handler for scroll/resize
      this._repositionHandler = () => {
        try {
          if (this._headerOpen) this._positionHeaderDropdown();
        } catch (_e) {}
      };
      window.addEventListener("resize", this._repositionHandler);
      window.addEventListener("scroll", this._repositionHandler, true);

      // close on Esc and handle arrow/enter navigation
      this._boundHeaderEsc = (ev) => {
        if (ev.key === "Escape") this._closeHeaderDropdown();
      };
      document.addEventListener("keydown", this._boundHeaderEsc);
      document.addEventListener("keydown", this._dropdownKeyHandler);
    } catch (_e) {}
  }

  _closeHeaderDropdown() {
    try {
      const el = this.headerDropdownTarget;
      // animate out
      try {
        el.classList.remove("opacity-100", "translate-y-0");
        el.classList.add(
          "opacity-0",
          "translate-y-1",
          "transition",
          "ease-in",
          "duration-150",
        );
      } catch (_e) {}
      // after animation, hide
      setTimeout(() => {
        try {
          el.classList.add("hidden");
          el.classList.remove(
            "opacity-0",
            "translate-y-1",
            "transition",
            "ease-in",
            "duration-150",
          );
          // restore moved dropdown to original place if we moved it
          try {
            if (
              this._headerDropdownOriginal &&
              el.parentElement === document.body
            ) {
              const { parent, nextSibling } = this._headerDropdownOriginal;
              if (nextSibling) parent.insertBefore(el, nextSibling);
              else parent.appendChild(el);
              // clear inline styles
              el.style.position = "";
              el.style.left = "";
              el.style.top = "";
              el.style.width = "";
            }
          } catch (_e) {}
        } catch (_e) {}
      }, 160);
      this._setCaretOpen(false);
      this._headerOpen = false;
      if (this._outsideClickHandler) {
        document.removeEventListener("click", this._outsideClickHandler, true);
        this._outsideClickHandler = null;
      }
      if (this._boundHeaderEsc) {
        document.removeEventListener("keydown", this._boundHeaderEsc);
        this._boundHeaderEsc = null;
      }
      try {
        document.removeEventListener("keydown", this._dropdownKeyHandler);
      } catch (_e) {}
      // remove reposition listeners
      try {
        if (this._repositionHandler) {
          window.removeEventListener("resize", this._repositionHandler);
          window.removeEventListener("scroll", this._repositionHandler, true);
          this._repositionHandler = null;
        }
      } catch (_e) {}
      // disable drag scroll if active
      try {
        this._disableDragScroll();
      } catch (_e) {}
    } catch (_e) {}
  }

  _positionHeaderDropdown() {
    if (!this.hasHeaderDropdownTarget || !this.hasCaretButtonTarget) return;
    try {
      const el = this.headerDropdownTarget;
      const caret = this.caretButtonTarget;
      const rect = caret.getBoundingClientRect();
      // responsive: on small screens make dropdown full-width with small page padding
      const smallScreen = window.innerWidth < 640; // Tailwind 'sm' breakpoint
      el.style.position = "absolute";
      if (smallScreen) {
        // On small screens avoid full-bleed width (overlap issues).
        // Use a capped width (max 360px) and center the dropdown under the caret when possible.
        const pagePadding = 12; // keep a small margin from edges
        const maxWidth = Math.min(360, window.innerWidth - pagePadding * 2);
        const width = Math.max(220, maxWidth);
        const tentativeLeft =
          rect.left + rect.width / 2 - width / 2 + window.scrollX;
        const minLeft = window.scrollX + pagePadding;
        const maxLeft =
          window.scrollX + window.innerWidth - pagePadding - width;
        const left = Math.min(Math.max(tentativeLeft, minLeft), maxLeft);
        const top = rect.bottom + window.scrollY + 6;
        el.style.left = `${left}px`;
        el.style.top = `${top}px`;
        el.style.width = `${width}px`;
      } else {
        // compute left such that dropdown is centered under caret
        const ddWidth = el.offsetWidth || 280;
        const left = rect.left + rect.width / 2 - ddWidth / 2 + window.scrollX;
        const top = rect.bottom + window.scrollY + 6; // small gap
        el.style.left = `${Math.max(8, left)}px`;
        el.style.top = `${top}px`;
        // ensure dropdown doesn't overflow right edge
        const maxRight = window.scrollX + window.innerWidth - 8;
        const curRight = left + ddWidth;
        if (curRight > maxRight) {
          const shift = curRight - maxRight;
          el.style.left = `${Math.max(8, left - shift)}px`;
        }
        // clear any width set previously
        el.style.width = "";
      }
    } catch (_e) {}
  }

  _onDropdownKeydown(e) {
    if (!this.hasHeaderDropdownTarget) return;
    const root = this.headerDropdownTarget;
    const items = Array.from(root.querySelectorAll("button"));
    if (!items.length) return;

    const idx = items.indexOf(document.activeElement);

    if (e.key === "ArrowDown") {
      e.preventDefault();
      const next = items[(idx + 1) % items.length] || items[0];
      next.focus();
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      const prev =
        items[(idx - 1 + items.length) % items.length] ||
        items[items.length - 1];
      prev.focus();
    } else if (e.key === "Enter") {
      // activate current focused item if it's in the dropdown
      if (
        root.contains(document.activeElement) &&
        document.activeElement.tagName === "BUTTON"
      ) {
        e.preventDefault();
        document.activeElement.click();
        this._closeHeaderDropdown();
      }
    } else if (e.key === "Escape") {
      this._closeHeaderDropdown();
    }
  }

  // show category name in dropdown header when hovering an example
  showExampleCategory(e) {
    try {
      if (!this.hasHoverCategoryTarget) return;
      const cat = e.currentTarget.dataset.category || "";
      this.hoverCategoryTarget.textContent = cat;
    } catch (_e) {}
  }

  clearExampleCategory(_e) {
    try {
      if (!this.hasHoverCategoryTarget) return;
      this.hoverCategoryTarget.textContent = "";
    } catch (_e) {}
  }

  // --- Drag-to-scroll support for header dropdown (mouse drag / touch pointer) ---
  _enableDragScroll() {
    try {
      if (!this.hasHeaderScrollTarget) return;
      const el = this.headerScrollTarget;

      // state
      this._dragState = {
        active: false,
        pointerId: null,
        startY: 0,
        startScroll: 0,
      };

      // pointerdown: record initial position but DO NOT start dragging until a small
      // movement threshold is exceeded. This prevents tiny accidental pointermove
      // events from cancelling click events.
      this._pointerDownHandler = (e) => {
        // only left mouse button or touch/pen
        if (e.button && e.button !== 0) return;
        this._dragState.active = false; // not yet a drag
        this._dragState.pointerId = e.pointerId;
        this._dragState.startY = e.clientY;
        this._dragState.startScroll = el.scrollTop;
      };

      this._pointerMoveHandler = (e) => {
        if (!this._dragState) return;
        if (e.pointerId !== this._dragState.pointerId) return;
        const dy = e.clientY - this._dragState.startY;
        const threshold = 6; // pixels before we consider the gesture a drag

        // if not yet active, only activate when movement exceeds threshold
        if (!this._dragState.active) {
          if (Math.abs(dy) < threshold) return;
          this._dragState.active = true;
          try {
            el.setPointerCapture(e.pointerId);
          } catch (_e) {}
          // prevent accidental text selection while dragging
          el.classList.add("select-none");
        }

        // perform scroll while dragging
        el.scrollTop = this._dragState.startScroll - dy;
        // prevent default to avoid native touch scrolling while we're handling drag
        e.preventDefault();
      };

      this._pointerUpHandler = (_e) => {
        if (!this._dragState) return;
        try {
          if (this._dragState.pointerId != null)
            el.releasePointerCapture(this._dragState.pointerId);
        } catch (_e) {}
        this._dragState.active = false;
        this._dragState.pointerId = null;
        el.classList.remove("select-none");
      };

      el.addEventListener("pointerdown", this._pointerDownHandler, {
        passive: false,
      });
      el.addEventListener("pointermove", this._pointerMoveHandler, {
        passive: false,
      });
      el.addEventListener("pointerup", this._pointerUpHandler);
      el.addEventListener("pointercancel", this._pointerUpHandler);
    } catch (_e) {}
  }

  _disableDragScroll() {
    try {
      if (!this.hasHeaderScrollTarget) return;
      const el = this.headerScrollTarget;
      try {
        el.removeEventListener("pointerdown", this._pointerDownHandler, {
          passive: false,
        });
      } catch (_e) {}
      try {
        el.removeEventListener("pointermove", this._pointerMoveHandler, {
          passive: false,
        });
      } catch (_e) {}
      try {
        el.removeEventListener("pointerup", this._pointerUpHandler);
        el.removeEventListener("pointercancel", this._pointerUpHandler);
      } catch (_e) {}
      el.classList.remove("select-none");
      this._dragState = null;
      this._pointerDownHandler = null;
      this._pointerMoveHandler = null;
      this._pointerUpHandler = null;
    } catch (_e) {}
  }

  _setCaretOpen(open) {
    try {
      if (!this.hasCaretButtonTarget) return;
      const el = this.caretButtonTarget;
      // Do NOT rotate or flip the button when opening the dropdown.
      // Keep a11y state via aria-expanded instead.
      try {
        el.setAttribute("aria-expanded", !!open);
      } catch (_e) {}
    } catch (_e) {}
  }

  filterExamples(e) {
    const q = (e.target.value || "").trim().toLowerCase();
    const selects = Array.from(
      document.querySelectorAll(
        '[data-regexp-examples-target="exampleSelect"]',
      ),
    );
    selects.forEach((sel) => {
      Array.from(sel.options).forEach((opt) => {
        const text = (
          (opt.textContent || "") +
          " " +
          (opt.dataset.pattern || "") +
          " " +
          (opt.dataset.test || "")
        ).toLowerCase();
        const match = q === "" || text.indexOf(q) !== -1;
        opt.hidden = !match;
      });

      // if current selected option is hidden, move to first visible
      const selected = sel.options[sel.selectedIndex];
      if (selected?.hidden) {
        const first = Array.from(sel.options).find((o) => !o.hidden);
        if (first) {
          sel.value = first.value;
          sel.dispatchEvent(new Event("change", { bubbles: true }));
        }
      }
    });
  }

  trapFocus(modal) {
    const focusable = modal.querySelectorAll(
      'a[href], button:not([disabled]), textarea, input, select, [tabindex]:not([tabindex="-1"])',
    );
    if (!focusable.length) return;
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    first.focus();
    this._focusHandler = (e) => {
      if (e.key !== "Tab") return;
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        const _sel = this._primarySelect || this._selectElements?.[0];
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    };
    modal.addEventListener("keydown", this._focusHandler);
  }

  // result observer & update
  _startResultObserver() {
    const frame = document.getElementById("regexp");
    if (!frame) return;
    this._observer = new MutationObserver(() => {
      if (!this.modalTarget.classList.contains("hidden"))
        this._updateModalResult();
    });
    this._observer.observe(frame, { childList: true, subtree: true });
  }

  _updateModalResult() {
    if (!this.hasModalResultTarget) return;
    const frame = document.getElementById("regexp");
    if (!frame) return;
    const clone = frame.cloneNode(true);
    // avoid duplicate ids
    const ts = Date.now();
    clone.querySelectorAll("[id]").forEach((el) => {
      const old = el.getAttribute("id");
      if (old) el.setAttribute("id", `${old}-modal-${ts}`);
    });
    clone.id = `${clone.id || "regexp"}-modal-${ts}`;
    this.modalResultTarget.innerHTML = "";
    this.modalResultTarget.appendChild(clone);
  }
}
