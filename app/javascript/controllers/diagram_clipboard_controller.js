import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tooltip"];

  open(event) {
    event.stopPropagation();
    // Copy SVG content from source to modal content container
    this.contentTarget.innerHTML = this.sourceTarget.innerHTML;
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

  async copyPng(event) {
    // Find the SVG (railroad diagram) in the diagram area from the clipboard button's parent element
    const button = event.currentTarget;
    // Find the svg inside [data-diagram-modal-target="source"] within .flex.flex-col ...
    const flexCol = button.closest(".flex.flex-col");
    let svg = null;
    if (flexCol) {
      const diagramSource = flexCol.querySelector(
        '[data-diagram-modal-target="source"]',
      );
      if (diagramSource) {
        svg = diagramSource.querySelector("svg");
      }
    }
    if (!svg) {
      alert("SVG not found");
      return;
    }
    // Clone the SVG and inject <style> for inline styles
    const svgClone = svg.cloneNode(true);
    // Add required styles inline
    const style = document.createElement("style");
    style.textContent = `
      svg.railroad-diagram { background-color: hsl(30, 20%, 95%); }
      svg.railroad-diagram path { stroke-width: 3; stroke: black; fill: rgba(0,0,0,0); }
      svg.railroad-diagram text { font: bold 14px monospace; text-anchor: middle; }
      svg.railroad-diagram text.label { text-anchor: start; }
      svg.railroad-diagram text.comment { font: italic 12px monospace; }
      svg.railroad-diagram rect { stroke-width: 3; stroke: black; fill: hsl(120, 100%, 90%); }
      svg.railroad-diagram rect.group-box { stroke: gray; stroke-dasharray: 10 5; fill: none; }
    `;
    svgClone.insertBefore(style, svgClone.firstChild);
    // Serialize the SVG
    const svgData = new XMLSerializer().serializeToString(svgClone);
    const svgBlob = new Blob([svgData], { type: "image/svg+xml" });
    const url = URL.createObjectURL(svgBlob);
    const img = new window.Image();
    img.onload = async () => {
      const canvas = document.createElement("canvas");
      canvas.width = img.width;
      canvas.height = img.height;
      const ctx = canvas.getContext("2d");
      ctx.drawImage(img, 0, 0);
      canvas.toBlob(async (blob) => {
        try {
          await navigator.clipboard.write([
            new window.ClipboardItem({ "image/png": blob }),
          ]);
          // Show tooltip (Copied!)
          const tooltip = button.querySelector(
            '[data-diagram-clipboard-target="tooltip"]',
          );
          if (tooltip) {
            tooltip.classList.remove("opacity-0", "invisible");
            setTimeout(
              () => tooltip.classList.add("opacity-0", "invisible"),
              1000,
            );
          }
        } catch (e) {
          alert(`Failed·to·copy·PNG·to·clipboard:·${e}`);
        }
      }, "image/png");
      URL.revokeObjectURL(url);
    };
    img.onerror = () => {
      alert("Failed to load SVG image");
      URL.revokeObjectURL(url);
    };
    img.src = url;
  }

  // (Unused) Simple feedback for copy action
  showCopiedTooltip() {
    // Simple feedback (not used in current implementation)
    const btn = this.svgTarget;
    btn.classList.add("text-green-500");
    setTimeout(() => btn.classList.remove("text-green-500"), 1000);
  }
}
