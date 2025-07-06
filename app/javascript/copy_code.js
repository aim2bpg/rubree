const setupCopyListeners = () => {
  document.querySelectorAll("code.cursor-pointer").forEach((el) => {
    el.addEventListener("click", () => {
      const text = el.textContent;
      navigator.clipboard
        .writeText(text)
        .then(() => {
          showTooltip(el, "Copied!");
        })
        .catch(() => {
          alert("Failed to copy to clipboard.");
        });
    });
  });
};

const showTooltip = (el, message) => {
  const tooltip = document.createElement("div");
  tooltip.textContent = message;
  tooltip.className = `
    absolute z-50 bg-gray-800 text-white text-xs py-1 px-2 rounded 
    shadow-lg transition-opacity duration-300 pointer-events-none
  `;
  tooltip.style.top = `${el.getBoundingClientRect().top - 30 + window.scrollY}px`;
  tooltip.style.left = `${el.getBoundingClientRect().left + el.offsetWidth / 2 - 30}px`;
  tooltip.style.opacity = "0";

  document.body.appendChild(tooltip);

  requestAnimationFrame(() => {
    tooltip.style.opacity = "1";
  });

  setTimeout(() => {
    tooltip.style.opacity = "0";
    setTimeout(() => {
      tooltip.remove();
    }, 300);
  }, 1000);
};

document.addEventListener("turbo:load", setupCopyListeners);
