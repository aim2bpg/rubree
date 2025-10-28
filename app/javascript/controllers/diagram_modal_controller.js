import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "content", "source"];
  connect() {
    this._boundEsc = this._onEsc.bind(this);
    this._focusHandler = null;
    this._previousActive = null;
  }

  open(event) {
    event.stopPropagation();
    // Get regex pattern from the clicked button itself
    let pattern = "";
    if (event?.currentTarget) {
      pattern = event.currentTarget.getAttribute("data-pattern") || "";
    }
    // Get SVG content
    const svgHtml = this.sourceTarget.innerHTML;
    // Build sticky label and scrollable SVG container
    let labelHtml = "";
    if (pattern) {
      // Escape for HTML
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

      // Center the label and avoid overlap with the top-right close button by
      // making it sticky slightly below the top and adding extra right padding.
      // Also match horizontal padding with the SVG container so the label and
      // diagram visually align.
      labelHtml = `<div class="sticky top-3 z-10 text-base font-mono font-bold text-gray-800 bg-gray-200 rounded px-3 py-1 mb-2 w-full text-center" style="padding-right:48px;">Regex: <span class="break-all">${escapeHtml(pattern)}</span></div>`;
    }
    // SVG container: horizontal scroll, max height, drag-scroll controller for hand-drag
    // Use a white background and a subtle ring/shadow so the diagram looks clean
    // inside the modal (remove the earlier dark bg and thick border).
    const svgContainer = `<div class='overflow-auto w-full grow bg-white rounded p-3 ring-1 ring-gray-200 shadow-sm cursor-grab' style='max-height:calc(80vh-48px);' data-controller="drag-scroll">${svgHtml}</div>`;
    this.contentTarget.innerHTML = labelHtml + svgContainer;

    // Fade-in: ensure visible and animate opacity
    this.modalTarget.classList.remove("hidden");
    // ensure starting opacity class removed and then add visible opacity
    this.modalTarget.classList.remove("opacity-0");
    this.modalTarget.classList.add("opacity-100");

    // accessibility: store previous focus and trap focus inside modal
    this._previousActive = document.activeElement;
    this.trapFocus(this.modalTarget);
    document.addEventListener("keydown", this._boundEsc);
  }

  close(event) {
    event.stopPropagation();
    // fade out by switching opacity, then hide after transition
    this.modalTarget.classList.remove("opacity-100");
    this.modalTarget.classList.add("opacity-0");
    setTimeout(() => {
      this.modalTarget.classList.add("hidden");
      // Clear modal content to free memory
      this.contentTarget.innerHTML = "";
      // restore focus
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
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    };
    modal.addEventListener("keydown", this._focusHandler);
  }

  releaseFocus() {
    if (this.modalTarget && this._focusHandler) {
      this.modalTarget.removeEventListener("keydown", this._focusHandler);
      this._focusHandler = null;
    }
    try {
      if (this._previousActive) this._previousActive.focus();
    } catch (_e) {}
    this._previousActive = null;
  }
}
