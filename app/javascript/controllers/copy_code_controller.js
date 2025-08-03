import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="copy-code"
export default class extends Controller {
  static targets = ["source"];

  copy() {
    const text = this.sourceTarget.textContent;

    navigator.clipboard
      .writeText(text)
      .then(() => {
        this.showTooltip("Copied!");
      })
      .catch(() => {
        alert("Failed to copy to clipboard.");
      });
  }

  showTooltip(message) {
    const tooltip = document.createElement("div");
    tooltip.textContent = message;
    tooltip.className = `
      absolute z-50 bg-gray-800 text-white text-xs py-1 px-2 rounded 
      shadow-lg transition-opacity duration-300 pointer-events-none
    `;
    const rect = this.element.getBoundingClientRect();
    tooltip.style.top = `${rect.top - 30 + window.scrollY}px`;
    tooltip.style.left = `${rect.left + rect.width / 2 - 30}px`;
    tooltip.style.opacity = "0";

    document.body.appendChild(tooltip);

    requestAnimationFrame(() => {
      tooltip.style.opacity = "1";
    });

    setTimeout(() => {
      tooltip.style.opacity = "0";
      setTimeout(() => tooltip.remove(), 300);
    }, 1000);
  }
}
