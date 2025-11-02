export function moveFormIntoModal(formEl, modalContentEl) {
  if (!formEl || !modalContentEl) return null;
  const state = {
    el: formEl,
    parent: formEl.parentNode,
    nextSibling: formEl.nextSibling,
    moved: false,
  };

  function move() {
    try {
      if (!state.moved) {
        state.parent = formEl.parentNode;
        state.nextSibling = formEl.nextSibling;
        modalContentEl.appendChild(formEl);
        state.moved = true;
      }
    } catch (_e) {}
  }

  function restore() {
    try {
      if (state.moved && state.parent) {
        if (state.nextSibling)
          state.parent.insertBefore(state.el, state.nextSibling);
        else state.parent.appendChild(state.el);
        state.moved = false;
      }
    } catch (_e) {}
  }

  return { move, restore, state };
}
