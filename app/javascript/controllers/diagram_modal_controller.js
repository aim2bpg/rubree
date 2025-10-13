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
    // Add label at the top
    let labelHtml = "";
    if (pattern) {
      labelHtml = `<div class='mb-2 text-base font-mono font-bold text-gray-800 bg-gray-200 rounded px-2 py-1'>Regex: <span class='break-all'>${pattern}</span></div>`;
    }
    this.contentTarget.innerHTML = labelHtml + svgHtml;
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
