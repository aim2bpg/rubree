import { Controller } from "@hotwired/stimulus";
import { trapFocus as sharedTrapFocus } from "./lib/trap_focus";

export default class extends Controller {
  static targets = ["modal", "content", "source"];
  connect() {
    this._boundEsc = this._onEsc.bind(this);
    this._focusHandler = null;
    this._previousActive = null;
  }

  open(event) {
    event.stopPropagation();
    let pattern = "";
    if (event?.currentTarget) {
      pattern = event.currentTarget.getAttribute("data-pattern") || "";
    }
    const svgHtml = this.sourceTarget.innerHTML;
    let labelHtml = "";
    if (pattern) {
      const escapeHtml = (str) =>
        str.replace(
          /[&<>'"]/g,
          (c) =>
            ({
              "&": "&amp;",
              "<": "&lt;",
              ">": "&gt;",
              "'": "&#39;",
              '"': "&quot;",
            })[c],
        );

      labelHtml = `<div class="sticky top-0 z-10 text-base font-mono font-bold text-gray-800 bg-gray-200 rounded px-4 py-1 mb-2 w-full text-center" style="padding-right:48px;">Regex: <span class="break-all">${escapeHtml(pattern)}</span></div>`;
    }
    const svgContainer = `<div class='overflow-auto w-full grow cursor-grab active:cursor-grabbing' style='max-height:calc(80vh-48px);' data-controller="drag-scroll" data-drag-scroll-horizontal-only-value="true">${svgHtml}</div>`;
    this.contentTarget.innerHTML = labelHtml + svgContainer;

    this.modalTarget.classList.remove("hidden");
    this.modalTarget.classList.remove("opacity-0");
    this.modalTarget.classList.add("opacity-100");

    this._previousActive = document.activeElement;
    try {
      this._removeModalFocusTrap = sharedTrapFocus(this.modalTarget);
    } catch (_e) {
      this._removeModalFocusTrap = null;
    }
    document.addEventListener("keydown", this._boundEsc);
  }

  close(event) {
    event.stopPropagation();
    this.modalTarget.classList.remove("opacity-100");
    this.modalTarget.classList.add("opacity-0");
    setTimeout(() => {
      this.modalTarget.classList.add("hidden");
      this.contentTarget.innerHTML = "";
      this.releaseFocus();
      document.removeEventListener("keydown", this._boundEsc);
    }, 220);
  }

  stopPropagation(event) {
    event.stopPropagation();
  }

  _onEsc(e) {
    if (e.key === "Escape") this.close(e);
  }

  trapFocus(modal) {
    try {
      this._removeModalFocusTrap = sharedTrapFocus(modal);
    } catch (_e) {
      this._removeModalFocusTrap = null;
    }
  }

  releaseFocus() {
    if (this.modalTarget && this._removeModalFocusTrap) {
      try {
        this._removeModalFocusTrap();
      } catch (_e) {}
      this._removeModalFocusTrap = null;
    }
    try {
      if (this._previousActive) this._previousActive.focus();
    } catch (_e) {}
    this._previousActive = null;
  }
}
