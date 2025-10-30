import { hideModal, showModal } from "../lib/modal_orchestrator";
import { trapFocus as sharedTrapFocus } from "../lib/trap_focus";
import { moveFormIntoModal } from "./modal_form_mover";
import { createResultObserver } from "./modal_helpers";

export function openModal(controller, event) {
  event?.preventDefault();
  if (!controller.hasModalTarget || !controller.hasModalContentTarget) return;

  const mainForm = document.querySelector(
    'form[data-controller*="regexp-form"]',
  );
  if (mainForm && !controller._movedForm) {
    try {
      controller._movedForm = moveFormIntoModal(
        mainForm,
        controller.modalContentTarget,
      );
    } catch (_e) {
      controller._movedForm = null;
    }
  }

  const container = controller.hasRootTarget
    ? controller.rootTarget
    : controller.element;
  const clone = container.cloneNode(true);
  clone.querySelectorAll('turbo-frame, [id="regexp"]').forEach((el) => {
    el.remove();
  });
  clone.querySelectorAll(".hidden").forEach((el) => {
    el.classList.remove("hidden");
  });

  controller.modalContentTarget.innerHTML = "";
  if (controller._movedForm) {
    try {
      controller._movedForm.move();
    } catch (_e) {}
  }
  controller.modalContentTarget.appendChild(clone);

  controller.modalTarget.classList.remove("hidden");
  controller._previousActive = document.activeElement;
  if (controller._primarySelect) controller._primarySelect.focus();
  else controller.modalTarget.focus();
  // use modal orchestrator to show and trap focus
  try {
    controller._removeModalFocusTrap = showModal(controller.modalTarget);
  } catch (_e) {
    controller._removeModalFocusTrap = null;
  }
  document.addEventListener("keydown", controller._boundEsc);

  try {
    controller._modalResultObserver = createResultObserver(
      controller.modalTarget,
      controller.modalResultTarget,
    );
    controller._modalResultObserver.start();
    controller._modalResultObserver.update();
  } catch (_e) {}
}

export function closeModal(controller, event) {
  event?.preventDefault();
  if (!controller.hasModalTarget || !controller.hasModalContentTarget) return;

  // hide via modal orchestrator to keep animation and focus handling consistent
  try {
    hideModal(controller.modalTarget, {
      clearContentEl: controller.modalContentTarget,
      duration: 160,
      removeFocus: controller._removeModalFocusTrap,
    });
  } catch (_e) {
    controller.modalTarget.classList.add("hidden");
  }
  try {
    if (
      controller._movedForm &&
      typeof controller._movedForm.restore === "function"
    ) {
      controller._movedForm.restore();
    } else if (controller._movedForm) {
      // fallback
      try {
        const { el, parent, nextSibling } = controller._movedForm;
        if (nextSibling) parent.insertBefore(el, nextSibling);
        else parent.appendChild(el);
      } catch (_e) {}
    }
  } catch (_e) {}

  controller.modalContentTarget.innerHTML = "";
  if (controller.hasModalResultTarget)
    controller.modalResultTarget.innerHTML = "";
  try {
    if (controller._previousActive) controller._previousActive.focus();
  } catch (_e) {}
  document.removeEventListener("keydown", controller._boundEsc);
  try {
    if (controller._removeModalFocusTrap) controller._removeModalFocusTrap();
  } catch (_e) {}

  try {
    if (controller._modalResultObserver) {
      controller._modalResultObserver.stop();
      controller._modalResultObserver = null;
    }
  } catch (_e) {}
  if (controller._observer) {
    controller._observer.disconnect();
    controller._observer = null;
  }
}

export function onEsc(controller, e) {
  if (e.key === "Escape") closeModal(controller);
}

export function restoreForm(controller) {
  try {
    const { el, parent, nextSibling } = controller._movedForm;
    if (nextSibling) parent.insertBefore(el, nextSibling);
    else parent.appendChild(el);
  } catch (_e) {}
  controller._movedForm = null;
}

export function trapFocus(_controller, modal) {
  // delegate to modal_helpers.trapFocus but keep compatibility
  try {
    return sharedTrapFocus(modal);
  } catch (_e) {
    return () => {};
  }
}

export function startResultObserver(controller) {
  const frame = document.getElementById("regexp");
  if (!frame) return;
  controller._observer = new MutationObserver(() => {
    if (!controller.modalTarget.classList.contains("hidden"))
      updateModalResult(controller);
  });
  controller._observer.observe(frame, { childList: true, subtree: true });
}

export function updateModalResult(controller) {
  try {
    if (
      controller._modalResultObserver &&
      typeof controller._modalResultObserver.update === "function"
    ) {
      controller._modalResultObserver.update();
      return;
    }
    if (!controller.hasModalResultTarget) return;
    const frame = document.getElementById("regexp");
    if (!frame) return;
    const clone = frame.cloneNode(true);
    const ts = Date.now();
    clone.querySelectorAll("[id]").forEach((el) => {
      const old = el.getAttribute("id");
      if (old) el.setAttribute("id", `${old}-modal-${ts}`);
    });
    clone.id = `${clone.id || "regexp"}-modal-${ts}`;
    controller.modalResultTarget.innerHTML = "";
    controller.modalResultTarget.appendChild(clone);
  } catch (_e) {}
}
