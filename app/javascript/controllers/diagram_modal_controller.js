import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "content", "source"];

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
      labelHtml = `<div class='sticky top-0 z-10 text-base font-mono font-bold text-gray-800 bg-gray-200 rounded px-2 py-1 mb-2 w-full'>Regex: <span class='break-all'>${escapeHtml(pattern)}</span></div>`;
    }
    // SVG container: horizontal scroll, max height, drag-scroll controller for hand-drag
    const svgContainer = `<div class='overflow-auto w-full grow bg-gray-800 rounded p-2 border border-gray-600 cursor-grab' style='max-height:calc(80vh-48px);' data-controller="drag-scroll">${svgHtml}</div>`;
    this.contentTarget.innerHTML = labelHtml + svgContainer;
    this.modalTarget.classList.remove("hidden");
  }

  close(event) {
    event.stopPropagation();
    this.modalTarget.classList.add("hidden");
    // Clear modal content to free memory
    this.contentTarget.innerHTML = "";
  }

  stopPropagation(event) {
    event.stopPropagation();
  }
}
