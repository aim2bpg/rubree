export function updateSelectionPersistence(
  itemOrIdx,
  examplesSelector,
  classString,
  prevState = {},
) {
  try {
    const examples = Array.from(document.querySelectorAll(examplesSelector));

    let newEl = null;
    if (itemOrIdx && itemOrIdx.nodeType === 1) {
      const passedEl = itemOrIdx;
      const idxInExamples = examples.indexOf(passedEl);
      if (idxInExamples >= 0) {
        newEl = examples[idxInExamples];
      } else {
        const pat = passedEl.dataset.pattern || null;
        const tst = passedEl.dataset.test || null;
        const sub = passedEl.dataset.substitution || null;
        newEl =
          examples.find((e) => {
            try {
              return (
                (pat === null || e.dataset.pattern === pat) &&
                (tst === null || e.dataset.test === tst) &&
                (sub === null || e.dataset.substitution === sub)
              );
            } catch (_err) {
              return false;
            }
          }) || null;
      }
    } else if (typeof itemOrIdx === "number") {
      newEl = examples[itemOrIdx] || null;
    }

    const removeClasses = (el) => {
      if (!el || !classString) return;
      try {
        classString.split(" ").forEach((c) => {
          if (c) el.classList.remove(c);
        });
      } catch (_e) {}
    };

    const addClasses = (el) => {
      if (!el || !classString) return;
      try {
        classString.split(" ").forEach((c) => {
          if (c) el.classList.add(c);
        });
      } catch (_e) {}
    };

    // remove previous
    try {
      if (prevState?.el && prevState.el.nodeType === 1) {
        removeClasses(prevState.el);
      } else if (
        typeof prevState.index === "number" &&
        examples[prevState.index]
      ) {
        removeClasses(examples[prevState.index]);
      }
    } catch (_e) {}

    if (newEl) {
      try {
        addClasses(newEl);
        return { el: newEl, index: examples.indexOf(newEl) };
      } catch (_e) {
        return { el: null, index: null };
      }
    }
    return { el: null, index: null };
  } catch (_e) {
    return { el: null, index: null };
  }
}
