import { enableDragScroll } from "./drag_scroll";
import { attachDropdownLifecycle } from "./dropdown_helpers";
import { positionHeaderDropdown } from "./dropdown_positioner";

export function toggleHeaderDropdown(controller, e) {
  e?.preventDefault();
  if (!controller.hasHeaderDropdownTarget) return;
  if (controller._headerOpen) _closeHeaderDropdown(controller);
  else _openHeaderDropdown(controller);
}

export function _openHeaderDropdown(controller) {
  try {
    let el = controller.headerDropdownTarget;
    if (el && el.parentElement !== document.body) {
      try {
        controller._headerDropdownOriginal = {
          parent: el.parentElement,
          nextSibling: el.nextSibling,
        };
        document.body.appendChild(el);
      } catch (_e) {}
      el = controller.headerDropdownTarget;
    }

    if (el) {
      el.style.position = "absolute";
      el.style.left = "0px";
      el.style.top = "0px";
      el.style.width = "";
    }
    el.classList.remove("hidden");
    el.classList.remove("opacity-100", "translate-y-0");
    el.classList.add("opacity-0", "translate-y-1");
    try {
      _positionHeaderDropdown(controller);
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
    controller._setCaretOpen(true);
    controller._headerOpen = true;

    try {
      const examples = Array.from(
        controller.headerDropdownTarget.querySelectorAll("button"),
      );
      if (
        typeof controller._lastSelectedIndex === "number" &&
        examples[controller._lastSelectedIndex]
      ) {
        const sel = examples[controller._lastSelectedIndex];
        try {
          controller._applyLastSelectedClass(sel);
          sel.focus();
          sel.scrollIntoView({ block: "center", behavior: "auto" });
          const cat = sel.dataset.category || "";
          if (controller.hasHoverCategoryTarget)
            controller.hoverCategoryTarget.textContent = cat;
        } catch (_e) {}
      } else {
        const first = controller.headerDropdownTarget.querySelector("button");
        if (first) first.focus();
      }
    } catch (_e) {}

    try {
      _enableDragScroll(controller);
    } catch (_e) {}

    try {
      controller._dropdownLifecycle = attachDropdownLifecycle({
        dropdownEl: controller.headerDropdownTarget,
        caretEl: controller.caretButtonTarget,
        onClose: () => _closeHeaderDropdown(controller),
        onReposition: () => _positionHeaderDropdown(controller),
      });
    } catch (_e) {}

    document.addEventListener("keydown", controller._dropdownKeyHandler);
  } catch (_e) {}
}

export function _closeHeaderDropdown(controller) {
  try {
    const el = controller.headerDropdownTarget;
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
        try {
          if (
            controller._headerDropdownOriginal &&
            el.parentElement === document.body
          ) {
            const { parent, nextSibling } = controller._headerDropdownOriginal;
            if (nextSibling) parent.insertBefore(el, nextSibling);
            else parent.appendChild(el);
            el.style.position = "";
            el.style.left = "";
            el.style.top = "";
            el.style.width = "";
          }
        } catch (_e) {}
      } catch (_e) {}
    }, 160);
    controller._setCaretOpen(false);
    controller._headerOpen = false;
    try {
      if (controller._dropdownLifecycle) {
        controller._dropdownLifecycle.detach();
        controller._dropdownLifecycle = null;
      }
    } catch (_e) {}
    try {
      controller._boundHeaderEsc = null;
    } catch (_e) {}
    try {
      document.removeEventListener("keydown", controller._dropdownKeyHandler);
    } catch (_e) {}
    try {
      if (controller._repositionHandler) {
        window.removeEventListener("resize", controller._repositionHandler);
        window.removeEventListener(
          "scroll",
          controller._repositionHandler,
          true,
        );
        controller._repositionHandler = null;
      }
    } catch (_e) {}
    try {
      _disableDragScroll(controller);
    } catch (_e) {}
  } catch (_e) {}
}

export function _positionHeaderDropdown(controller) {
  if (!controller.hasHeaderDropdownTarget || !controller.hasCaretButtonTarget)
    return;
  try {
    positionHeaderDropdown(
      controller.headerDropdownTarget,
      controller.caretButtonTarget,
    );
  } catch (_e) {}
}

export function _onDropdownKeydown(controller, e) {
  if (!controller.hasHeaderDropdownTarget) return;
  const root = controller.headerDropdownTarget;
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
      items[(idx - 1 + items.length) % items.length] || items[items.length - 1];
    prev.focus();
  } else if (e.key === "Enter") {
    if (
      root.contains(document.activeElement) &&
      document.activeElement.tagName === "BUTTON"
    ) {
      e.preventDefault();
      const cur = document.activeElement;
      document.activeElement.click();
      try {
        controller._setLastSelectedIndex(cur);
      } catch (_e) {}
      _closeHeaderDropdown(controller);
    }
  } else if (e.key === "Escape") {
    _closeHeaderDropdown(controller);
  }
}

export function showExampleCategory(controller, e) {
  try {
    if (!controller.hasHoverCategoryTarget) return;
    const cat = e.currentTarget.dataset.category || "";
    controller.hoverCategoryTarget.textContent = cat;
  } catch (_e) {}
}

export function clearExampleCategory(controller) {
  try {
    if (!controller.hasHoverCategoryTarget) return;
    controller.hoverCategoryTarget.textContent = "";
  } catch (_e) {}
}

export function _enableDragScroll(controller) {
  try {
    if (!controller.hasHeaderScrollTarget) return;
    controller._dragScrollObj = enableDragScroll(
      controller.headerScrollTarget,
      controller._headerScrollTop,
    );
  } catch (_e) {}
}

export function _disableDragScroll(controller) {
  try {
    if (controller._dragScrollObj) {
      try {
        controller._headerScrollTop = controller._dragScrollObj.getScrollTop();
      } catch (_e) {}
      try {
        controller._dragScrollObj.disable();
      } catch (_e) {}
      controller._dragScrollObj = null;
    }
  } catch (_e) {}
}

export function _setCaretOpen(controller, open) {
  try {
    if (!controller.hasCaretButtonTarget) return;
    const el = controller.caretButtonTarget;
    try {
      el.setAttribute("aria-expanded", !!open);
    } catch (_e) {}
  } catch (_e) {}
}
