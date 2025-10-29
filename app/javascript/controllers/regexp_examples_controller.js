import { Controller } from "@hotwired/stimulus";
import { enableDragScroll } from "./regexp_examples/drag_scroll";
import { attachDropdownLifecycle } from "./regexp_examples/dropdown_helpers";
import { positionHeaderDropdown } from "./regexp_examples/dropdown_positioner";
import { moveFormIntoModal } from "./regexp_examples/modal_form_mover";
import {
  createResultObserver,
  trapFocus as modalTrapFocus,
} from "./regexp_examples/modal_helpers";
import { updateSelectionPersistence } from "./regexp_examples/selection_persistence";

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
    this._modalResultObserver = null;
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
    // remember last scroll position inside the header dropdown so we can restore it
    this._headerScrollTop = 0;
    // remember last selected example element/index so we can re-apply highlight/focus
    this._lastSelectedElement = null;
    this._lastSelectedIndex = null;
    // persistent selection marker: left-edge border + padding so hover background remains visible
    // stored as a space-separated list of classes; helpers below will add/remove each class
    this._lastSelectedClass = "border-l-4 border-blue-400 pl-4";
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
  }

  // helpers to add/remove the persistent set of classes (space-separated)
  _applyLastSelectedClass(el) {
    if (!el || !this._lastSelectedClass) return;
    try {
      this._lastSelectedClass.split(" ").forEach((c) => {
        if (c) el.classList.add(c);
      });
    } catch (_e) {}
  }

  _removeLastSelectedClass(el) {
    if (!el || !this._lastSelectedClass) return;
    try {
      this._lastSelectedClass.split(" ").forEach((c) => {
        if (c) el.classList.remove(c);
      });
    } catch (_e) {}
  }

  // --- Drag-to-scroll support for header dropdown (mouse drag / touch pointer) ---
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
    // remember the selection by element so we can restore highlight on reopen
    try {
      this._setLastSelectedIndex(event.currentTarget);
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
      // use modal_form_mover helper to manage move/restore
      try {
        this._movedForm = moveFormIntoModal(mainForm, this.modalContentTarget);
        // if we moved, mover.move() will be called below when inserting to modal
      } catch (_e) {
        this._movedForm = null;
      }
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
    if (this._movedForm) {
      try {
        this._movedForm.move();
      } catch (_e) {}
    }
    this.modalContentTarget.appendChild(clone);

    // show modal
    this.modalTarget.classList.remove("hidden");
    this._previousActive = document.activeElement;
    // focus select or modal
    if (this._primarySelect) this._primarySelect.focus();
    else this.modalTarget.focus();
    // use modal helper to trap focus (returns cleanup fn)
    try {
      this._removeModalFocusTrap = modalTrapFocus(this.modalTarget);
    } catch (_e) {}
    document.addEventListener("keydown", this._boundEsc);

    // start observing result frame for live updates via helper
    try {
      this._modalResultObserver = createResultObserver(
        this.modalTarget,
        this.modalResultTarget,
      );
      this._modalResultObserver.start();
      this._modalResultObserver.update();
    } catch (_e) {}
  }

  closeModal(event) {
    event?.preventDefault();
    if (!this.hasModalTarget || !this.hasModalContentTarget) return;

    this.modalTarget.classList.add("hidden");
    // restore moved form
    try {
      if (this._movedForm && typeof this._movedForm.restore === "function") {
        this._movedForm.restore();
      } else if (this._movedForm) {
        // fallback to legacy restore
        this._restoreForm();
      }
    } catch (_e) {}
    this.modalContentTarget.innerHTML = "";
    if (this.hasModalResultTarget) this.modalResultTarget.innerHTML = "";
    try {
      if (this._previousActive) this._previousActive.focus();
    } catch (_e) {}
    document.removeEventListener("keydown", this._boundEsc);
    try {
      if (this._removeModalFocusTrap) this._removeModalFocusTrap();
    } catch (_e) {}
    try {
      if (this._modalResultObserver) {
        this._modalResultObserver.stop();
        this._modalResultObserver = null;
      }
    } catch (_e) {}
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

      // focus previously selected item if present, otherwise first interactive item
      try {
        const examples = Array.from(
          this.headerDropdownTarget.querySelectorAll("button"),
        );
        if (
          typeof this._lastSelectedIndex === "number" &&
          examples[this._lastSelectedIndex]
        ) {
          const sel = examples[this._lastSelectedIndex];
          try {
            // apply persistent left-edge marker
            this._applyLastSelectedClass(sel);
            sel.focus();
            sel.scrollIntoView({ block: "center", behavior: "auto" });
            const cat = sel.dataset.category || "";
            if (this.hasHoverCategoryTarget)
              this.hoverCategoryTarget.textContent = cat;
          } catch (_e) {}
        } else {
          const first = this.headerDropdownTarget.querySelector("button");
          if (first) first.focus();
        }
      } catch (_e) {}

      // enable drag-to-scroll on the internal scroll area (mouse/touch drag)
      try {
        this._enableDragScroll();
      } catch (_e) {}

      // attach dropdown lifecycle handlers (outside click, reposition, Esc)
      try {
        this._dropdownLifecycle = attachDropdownLifecycle({
          dropdownEl: this.headerDropdownTarget,
          caretEl: this.caretButtonTarget,
          onClose: () => this._closeHeaderDropdown(),
          onReposition: () => this._positionHeaderDropdown(),
        });
      } catch (_e) {}

      // keyboard navigation for dropdown items (arrow/enter) remains handled
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
      try {
        if (this._dropdownLifecycle) {
          this._dropdownLifecycle.detach();
          this._dropdownLifecycle = null;
        }
      } catch (_e) {}
      try {
        this._boundHeaderEsc = null;
      } catch (_e) {}
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
      positionHeaderDropdown(this.headerDropdownTarget, this.caretButtonTarget);
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
      // do not update persistent selection on arrow navigation — only move focus
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      const prev =
        items[(idx - 1 + items.length) % items.length] ||
        items[items.length - 1];
      prev.focus();
      // do not update persistent selection on arrow navigation — only move focus
    } else if (e.key === "Enter") {
      // activate current focused item if it's in the dropdown
      if (
        root.contains(document.activeElement) &&
        document.activeElement.tagName === "BUTTON"
      ) {
        e.preventDefault();
        const cur = document.activeElement;
        document.activeElement.click();
        try {
          this._setLastSelectedIndex(cur);
        } catch (_e) {}
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
      // keep persistent marker visible while hovering (no removal) to avoid blinking
    } catch (_e) {}
  }

  clearExampleCategory(_e) {
    try {
      if (!this.hasHoverCategoryTarget) return;
      this.hoverCategoryTarget.textContent = "";
      // nothing to do here for marker; keep persistent marker always visible
    } catch (_e) {}
  }

  _setLastSelectedIndex(itemOrIdx) {
    try {
      const state = updateSelectionPersistence(
        itemOrIdx,
        '[data-regexp-examples-target="example"]',
        this._lastSelectedClass,
        { el: this._lastSelectedElement, index: this._lastSelectedIndex },
      );
      this._lastSelectedElement = state.el;
      this._lastSelectedIndex = state.index;
    } catch (_e) {}
  }

  // --- Drag-to-scroll: delegate to helper module ---
  _enableDragScroll() {
    try {
      if (!this.hasHeaderScrollTarget) return;
      this._dragScrollObj = enableDragScroll(
        this.headerScrollTarget,
        this._headerScrollTop,
      );
    } catch (_e) {}
  }

  _disableDragScroll() {
    try {
      if (this._dragScrollObj) {
        try {
          this._headerScrollTop = this._dragScrollObj.getScrollTop();
        } catch (_e) {}
        try {
          this._dragScrollObj.disable();
        } catch (_e) {}
        this._dragScrollObj = null;
      }
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
    // legacy: kept for backward compatibility, prefer createResultObserver helper
    const frame = document.getElementById("regexp");
    if (!frame) return;
    this._observer = new MutationObserver(() => {
      if (!this.modalTarget.classList.contains("hidden"))
        this._updateModalResult();
    });
    this._observer.observe(frame, { childList: true, subtree: true });
  }

  _updateModalResult() {
    try {
      if (
        this._modalResultObserver &&
        typeof this._modalResultObserver.update === "function"
      ) {
        this._modalResultObserver.update();
        return;
      }
      // fallback to previous behavior
      if (!this.hasModalResultTarget) return;
      const frame = document.getElementById("regexp");
      if (!frame) return;
      const clone = frame.cloneNode(true);
      const ts = Date.now();
      clone.querySelectorAll("[id]").forEach((el) => {
        const old = el.getAttribute("id");
        if (old) el.setAttribute("id", `${old}-modal-${ts}`);
      });
      clone.id = `${clone.id || "regexp"}-modal-${ts}`;
      this.modalResultTarget.innerHTML = "";
      this.modalResultTarget.appendChild(clone);
    } catch (_e) {}
  }
}
