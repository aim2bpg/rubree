import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  openPlayground(event) {
    event.preventDefault();

    const pattern = document.getElementById(
      "regular_expression_expression",
    )?.value;
    if (!pattern) return;

    const wrappedPattern = pattern.startsWith("/") ? pattern : `/${pattern}/`;
    const modal = this.createModal(wrappedPattern);
    document.body.appendChild(modal);

    const iframe = modal.querySelector("#recheck-iframe");
    iframe.src = "https://makenowjust-labs.github.io/recheck/playground/";

    iframe.onload = () => {
      setTimeout(() => {
        const iframeDoc =
          iframe.contentDocument || iframe.contentWindow.document;
        if (iframeDoc?.documentElement) {
          const scrollHeight = iframeDoc.documentElement.scrollHeight;
          const clientHeight = iframe.clientHeight;
          iframe.contentWindow.scrollTo(0, (scrollHeight - clientHeight) / 2);
        }
      }, 500);

      try {
        iframe.contentWindow.postMessage(
          {
            type: "SET_PATTERN",
            pattern: wrappedPattern,
          },
          "*",
        );
      } catch (e) {
        console.warn("postMessage failed:", e);
      }
    };
  }

  createModal(wrappedPattern) {
    const modal = document.createElement("div");
    modal.id = "recheck-modal";
    modal.className =
      "fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center";

    const locale = document.documentElement.lang || "en";
    const i18nData = {
      ja: {
        copyPattern: "パターンをコピー",
        copied: "コピーしました！",
        tip: "💡 「パターンをコピー」ボタンでパターンをコピーし、Playgroundの正規表現フィールドに貼り付けて「Check」ボタンを押してください。",
      },
      en: {
        copyPattern: "Copy Pattern",
        copied: "Copied!",
        tip: '💡 Click "Copy Pattern" to copy, paste into the Playground RegExp field, and press "Check".',
      },
    };

    const t = i18nData[locale] || i18nData.en;

    modal.innerHTML = `
      <div class="bg-gray-800 rounded-lg shadow-xl w-[95vw] sm:w-[85vw] md:w-[75vw] lg:w-[70vw] h-[90vh] sm:h-[88vh] md:h-[86vh] lg:h-[85vh] flex flex-col p-3 sm:p-4">
        <div class="flex justify-between items-center mb-3 sm:mb-4">
          <h2 class="text-lg sm:text-xl font-bold text-white">ReDoS Recheck Playground</h2>
          <button onclick="document.getElementById('recheck-modal').remove()" class="text-gray-400 hover:text-white text-xl sm:text-2xl leading-none">&times;</button>
        </div>
        
        <div class="flex-1 border border-gray-700 rounded overflow-hidden bg-white">
          <iframe id="recheck-iframe" class="w-full h-full" sandbox="allow-same-origin allow-scripts allow-forms allow-popups"></iframe>
        </div>
        
        <div class="mt-2 sm:mt-3 pt-3 border-t border-gray-700 flex items-center justify-between gap-3">
          <p class="text-xs text-gray-400 flex-1">${t.tip}</p>
          <button id="copy-pattern-btn" class="px-3 py-1.5 bg-blue-500 hover:bg-blue-600 text-white text-sm font-medium rounded transition-colors flex items-center gap-1.5 whitespace-nowrap">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
            </svg>
            <span class="copy-text">${t.copyPattern}</span>
            <span class="copied-text hidden">${t.copied}</span>
          </button>
        </div>
      </div>
    `;

    const copyBtn = modal.querySelector("#copy-pattern-btn");
    copyBtn.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(wrappedPattern);
        const copyText = copyBtn.querySelector(".copy-text");
        const copiedText = copyBtn.querySelector(".copied-text");
        copyText.classList.add("hidden");
        copiedText.classList.remove("hidden");
        setTimeout(() => {
          copyText.classList.remove("hidden");
          copiedText.classList.add("hidden");
        }, 2000);
      } catch (err) {
        console.error("Failed to copy pattern:", err);
        alert("Failed to copy pattern");
      }
    });

    modal.addEventListener("click", (e) => {
      if (e.target === modal) {
        modal.remove();
      }
    });

    return modal;
  }
}
