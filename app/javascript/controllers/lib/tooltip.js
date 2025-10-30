// Shared tooltip utilities for showing inline/floating copy-to-clipboard feedback.
export function showInlineTooltip(el, text = "Copied!") {
  if (!el) return;
  try {
    el.textContent = text;
    el.classList.remove("opacity-0", "invisible");
    setTimeout(() => {
      try {
        el.classList.add("opacity-0", "invisible");
      } catch (_e) {}
    }, 1000);
  } catch (_e) {}
}

export function showFloatingTooltip(targetEl, text = "Copied!") {
  if (!targetEl) return;
  try {
    const tooltip = document.createElement("div");
    tooltip.textContent = text;
    tooltip.className =
      "absolute z-50 bg-gray-800 text-white text-xs py-1 px-2 rounded shadow-lg transition-opacity duration-300 pointer-events-none";

    const rect = targetEl.getBoundingClientRect();
    tooltip.style.position = "absolute";
    // append first so offsetWidth is measurable
    document.body.appendChild(tooltip);
    tooltip.style.top = `${rect.top - 30 + window.scrollY}px`;
    tooltip.style.left = `${rect.left + rect.width / 2 - tooltip.offsetWidth / 2}px`;
    tooltip.style.opacity = "0";

    requestAnimationFrame(() => {
      tooltip.style.opacity = "1";
    });

    setTimeout(() => {
      tooltip.style.opacity = "0";
      setTimeout(() => tooltip.remove(), 300);
    }, 1000);
  } catch (_e) {}
}
