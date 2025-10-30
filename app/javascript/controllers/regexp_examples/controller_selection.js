import { updateSelectionPersistence } from "./selection_persistence";

export function applyLastSelectedClass(controller, el) {
  if (!el || !controller._lastSelectedClass) return;
  try {
    controller._lastSelectedClass.split(" ").forEach((c) => {
      if (c) el.classList.add(c);
    });
  } catch (_e) {}
}

export function removeLastSelectedClass(controller, el) {
  if (!el || !controller._lastSelectedClass) return;
  try {
    controller._lastSelectedClass.split(" ").forEach((c) => {
      if (c) el.classList.remove(c);
    });
  } catch (_e) {}
}

export function selectExample(controller, event) {
  const { pattern, test, options, substitution } = event.currentTarget.dataset;
  const patternEl =
    document.querySelector("input#regular_expression_expression") ||
    controller.patternTarget;
  const testEl =
    document.querySelector("textarea#regular_expression_test_string") ||
    controller.testTarget;

  if (patternEl && testEl) {
    patternEl.value = pattern || "";
    testEl.value = test || "";
    if (controller.hasOptionsTarget)
      controller.optionsTarget.value = options || "";
    if (controller.hasSubstitutionTarget)
      controller.substitutionTarget.value = substitution || "";
    patternEl.dispatchEvent(new Event("input", { bubbles: true }));
    testEl.dispatchEvent(new Event("input", { bubbles: true }));
    if (controller.hasSubstitutionTarget)
      controller.substitutionTarget.dispatchEvent(
        new Event("input", { bubbles: true }),
      );
  } else {
    console.warn("⚠️ Pattern or Test field not found");
  }

  try {
    if (controller._headerOpen) {
      const fromHeaderDropdown =
        controller.hasHeaderDropdownTarget &&
        controller.headerDropdownTarget.contains(event.currentTarget);
      if (!fromHeaderDropdown) controller._closeHeaderDropdown();
    }
  } catch (_e) {}

  try {
    controller._setLastSelectedIndex(event.currentTarget);
  } catch (_e) {}
}

export function selectFromSelect(controller, e) {
  const value = e.target.value;
  const examples = Array.from(
    document.querySelectorAll('[data-regexp-examples-target="example"]'),
  );
  const idx = parseInt(value, 10);
  let target = null;
  if (!Number.isNaN(idx) && examples[idx]) target = examples[idx];
  if (target) {
    target.dispatchEvent(new Event("click", { bubbles: true }));
    controller._updateModalResult();
  }
}

export function nextExample(controller, _event) {
  const sel = controller._primarySelect || controller._selectElements?.[0];
  if (!sel) return;
  const len = sel.options.length;
  if (!len) return;
  let idx = sel.selectedIndex;
  idx = (idx + 1) % len;
  sel.selectedIndex = idx;
  sel.dispatchEvent(new Event("change", { bubbles: true }));
}

export function prevExample(controller, _event) {
  const sel = controller._primarySelect || controller._selectElements?.[0];
  if (!sel) return;
  const len = sel.options.length;
  if (!len) return;
  let idx = sel.selectedIndex;
  idx = (idx - 1 + len) % len;
  sel.selectedIndex = idx;
  sel.dispatchEvent(new Event("change", { bubbles: true }));
}

export function tryExample(controller, _event) {
  const sel = controller._primarySelect || controller._selectElements?.[0];
  if (sel) {
    const len = sel.options.length;
    if (len) {
      const idx = Math.floor(Math.random() * len);
      sel.selectedIndex = idx;
      sel.dispatchEvent(new Event("change", { bubbles: true }));
    }
  } else {
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

  try {
    if (controller.hasDiceButtonTarget) {
      const el = controller.diceButtonTarget;
      el.classList.add("animate-bounce");
      if (controller._diceTimeout) clearTimeout(controller._diceTimeout);
      controller._diceTimeout = setTimeout(() => {
        el.classList.remove("animate-bounce");
        controller._diceTimeout = null;
      }, 600);
    }
  } catch (_e) {}
}

export function focusPrimarySelect(controller, e) {
  e?.preventDefault();
  const sel = controller._primarySelect || controller._selectElements?.[0];
  if (!sel) return;
  try {
    if (typeof sel.showPicker === "function") sel.showPicker();
  } catch (_err) {}
  try {
    sel.focus();
  } catch (_err) {}
  controller._setCaretOpen(true);
}

export function filterExamples(_controller, e) {
  const q = (e.target.value || "").trim().toLowerCase();
  const selects = Array.from(
    document.querySelectorAll('[data-regexp-examples-target="exampleSelect"]'),
  );
  selects.forEach((sel) => {
    Array.from(sel.options).forEach((opt) => {
      const text =
        `${opt.textContent || ""} ${opt.dataset.pattern || ""} ${opt.dataset.test || ""}`.toLowerCase();
      const match = q === "" || text.indexOf(q) !== -1;
      opt.hidden = !match;
    });

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

export function setLastSelectedIndex(controller, itemOrIdx) {
  try {
    const state = updateSelectionPersistence(
      itemOrIdx,
      '[data-regexp-examples-target="example"]',
      controller._lastSelectedClass,
      {
        el: controller._lastSelectedElement,
        index: controller._lastSelectedIndex,
      },
    );
    controller._lastSelectedElement = state.el;
    controller._lastSelectedIndex = state.index;
  } catch (_e) {}
}
