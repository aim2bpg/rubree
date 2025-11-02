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

  try {
    if (controller._lastSelectedElement) {
      try {
        removeLastSelectedClass(controller, controller._lastSelectedElement);
      } catch (_e) {}
    }
    const examples = Array.from(
      document.querySelectorAll('[data-regexp-examples-target="example"]'),
    );
    const idx = examples.indexOf(event.currentTarget);
    controller._lastSelectedElement = event.currentTarget;
    controller._lastSelectedIndex = idx >= 0 ? idx : null;
    try {
      applyLastSelectedClass(controller, event.currentTarget);
    } catch (_e) {}
  } catch (_e) {}

  try {
    const patternVal = event.currentTarget.dataset.pattern || "";
    const testVal = event.currentTarget.dataset.test || "";
    const mainExamples = Array.from(
      document.querySelectorAll('[data-regexp-examples-target="example"]'),
    );
    const match = mainExamples.find((el) => {
      try {
        return (
          (el.dataset.pattern || "") === patternVal &&
          (el.dataset.test || "") === testVal
        );
      } catch (_e) {
        return false;
      }
    });
    if (match) {
      try {
        if (
          controller._mainLastSelectedElement &&
          controller._mainLastSelectedElement !== match
        ) {
          removeLastSelectedClass(
            controller,
            controller._mainLastSelectedElement,
          );
        }
      } catch (_e) {}
      try {
        applyLastSelectedClass(controller, match);
        controller._mainLastSelectedElement = match;
      } catch (_e) {}

      try {
        const categoryEl = match.closest("[data-category]");
        const cat = categoryEl ? categoryEl.dataset.category : null;
        if (cat && controller.tabTargets) {
          const tab = controller.tabTargets.find(
            (t) => t.dataset.category === cat,
          );
          if (tab && typeof controller.showCategoryByElement === "function") {
            controller.showCategoryByElement(tab);
          }
          try {
            if (controller.hasHeaderDropdownTarget) {
              const headerBtn = controller.headerDropdownTarget.querySelector(
                `[data-header-category="${cat}"]`,
              );
              if (
                headerBtn &&
                typeof controller.showHeaderCategory === "function"
              ) {
                controller.showHeaderCategory({ currentTarget: headerBtn });
              }

              try {
                const hdrExamples = Array.from(
                  controller.headerDropdownTarget.querySelectorAll(
                    "button[data-pattern]",
                  ),
                );
                const hdrMatch = hdrExamples.find((el) => {
                  try {
                    return (
                      (el.dataset.pattern || "") ===
                        (event.currentTarget.dataset.pattern || "") &&
                      (el.dataset.test || "") ===
                        (event.currentTarget.dataset.test || "")
                    );
                  } catch (_e) {
                    return false;
                  }
                });
                if (hdrMatch) {
                  try {
                    removeLastSelectedClass(
                      controller,
                      controller._lastSelectedElement,
                    );
                  } catch (_e) {}
                  try {
                    applyLastSelectedClass(controller, hdrMatch);
                    controller._lastSelectedElement = hdrMatch;
                  } catch (_e) {}
                }
              } catch (_e) {}
            }
          } catch (_e) {}
        }
      } catch (_e) {}
    }
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
