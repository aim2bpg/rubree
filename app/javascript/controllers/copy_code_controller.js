import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "tooltip"];

  copy() {
    const text = this.sourceTarget.textContent.trim();

    if (!navigator.clipboard) {
      alert("Clipboard API is not supported in this browser.");
      return;
    }

    navigator.clipboard
      .writeText(text)
      .then(() => {
        if (this.hasTooltipTarget) {
          this.showInlineTooltip();
        } else {
          this.showFloatingTooltip();
        }
      })
      .catch(() => {
        alert("Failed to copy to clipboard.");
      });
  }

  showInlineTooltip() {
    this.tooltipTarget.classList.remove("opacity-0", "invisible");
    setTimeout(() => {
      this.tooltipTarget.classList.add("opacity-0", "invisible");
    }, 1000);
  }

  showFloatingTooltip() {
    const tooltip = document.createElement("div");
    tooltip.textContent = "Copied!";
    tooltip.className = `
      absolute z-50 bg-gray-800 text-white text-xs py-1 px-2 rounded 
      shadow-lg transition-opacity duration-300 pointer-events-none
    `;

    const rect = this.element.getBoundingClientRect();
    tooltip.style.position = "absolute";
    tooltip.style.top = `${rect.top - 30 + window.scrollY}px`;
    tooltip.style.left = `${rect.left + rect.width / 2 - tooltip.offsetWidth / 2}px`;
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
