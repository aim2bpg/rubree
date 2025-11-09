import { Controller } from "@hotwired/stimulus";
import { showFloatingTooltip, showInlineTooltip } from "./lib/tooltip";

export default class extends Controller {
  static targets = ["source", "tooltip"];

  copy(event) {
    const text = this.sourceTarget.textContent.trim();

    if (!navigator.clipboard) {
      alert("Clipboard API is not supported in this browser.");
      return;
    }

    navigator.clipboard
      .writeText(text)
      .then(() => {
        if (this.hasTooltipTarget) {
          showInlineTooltip(this.tooltipTarget);
        } else {
          const triggerButton = event?.currentTarget || this.element;
          const copiedText = triggerButton?.dataset?.copiedText;
          showFloatingTooltip(triggerButton, copiedText);
        }
      })
      .catch(() => {
        alert("Failed to copy to clipboard.");
      });
  }
}
