export function showInlineTooltip(el, text) {
  if (!el) return;
  try {
    const content =
      typeof text === "string" ? text : el.textContent || "Copied!";
    el.textContent = content;
    el.classList.remove("opacity-0", "invisible");
    setTimeout(() => {
      try {
        el.classList.add("opacity-0", "invisible");
      } catch (_e) {}
    }, 1000);
  } catch (_e) {}
}

export function showFloatingTooltip(targetEl, text) {
  if (!targetEl) return;
  try {
    const tooltip = document.createElement("div");
    const content =
      typeof text === "string"
        ? text
        : targetEl.dataset && Object.hasOwn(targetEl.dataset, "copiedText")
          ? targetEl.dataset.copiedText
          : "Copied!";
    tooltip.textContent = content;
    tooltip.className =
      "absolute z-50 bg-gray-800 text-white text-[11px] py-1 px-2 rounded shadow-lg transition-opacity duration-300 pointer-events-none";

    const rect = targetEl.getBoundingClientRect();
    tooltip.style.position = "absolute";
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
