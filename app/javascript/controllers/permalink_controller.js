import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "pattern", "test", "options", "substitution"];

  connect() {
    this.loadFromUrl();
  }

  loadFromUrl() {
    const params = new URLSearchParams(window.location.search);
    const encodedData = params.get("p");

    if (!encodedData || encodedData.trim() === "") return;

    try {
      // Decode URL-safe base64
      let base64 = encodedData.replace(/-/g, "+").replace(/_/g, "/");
      while (base64.length % 4) {
        base64 += "=";
      }

      // UTF-8 safe decode
      const binary = atob(base64);
      const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0));
      const decoded = new TextDecoder().decode(bytes);
      const data = JSON.parse(decoded);

      // Map short keys to full names
      const mapping = {
        r: "pattern",
        t: "test",
        o: "options",
        s: "substitution",
      };
      const fullData = {};
      for (const [key, value] of Object.entries(data)) {
        fullData[mapping[key] || key] = value;
      }

      // Find form fields by ID if targets not available
      const patternField = this.hasPatternTarget
        ? this.patternTarget
        : document.getElementById("regular_expression_expression");
      const testField = this.hasTestTarget
        ? this.testTarget
        : document.getElementById("regular_expression_test_string");
      const optionsField = this.hasOptionsTarget
        ? this.optionsTarget
        : document.getElementById("regular_expression_options");
      const substitutionField = this.hasSubstitutionTarget
        ? this.substitutionTarget
        : document.getElementById("regular_expression_substitution");

      if (fullData.pattern && patternField) {
        patternField.value = fullData.pattern;
      }
      if (fullData.test && testField) {
        testField.value = fullData.test;
      }
      if (fullData.options && optionsField) {
        optionsField.value = fullData.options;
      }
      if (fullData.substitution && substitutionField) {
        substitutionField.value = fullData.substitution;
      }

      // Trigger form submission
      const form = document.querySelector(
        'form[data-controller*="regexp-form"]',
      );
      if (form?.requestSubmit) {
        setTimeout(() => form.requestSubmit(), 100);
      }
    } catch (e) {
      console.error("Failed to load permalink:", e);
    }
  }

  share(event) {
    event.preventDefault();

    // Find form fields by ID if targets not available
    const patternField = this.hasPatternTarget
      ? this.patternTarget
      : document.getElementById("regular_expression_expression");
    const testField = this.hasTestTarget
      ? this.testTarget
      : document.getElementById("regular_expression_test_string");
    const optionsField = this.hasOptionsTarget
      ? this.optionsTarget
      : document.getElementById("regular_expression_options");
    const substitutionField = this.hasSubstitutionTarget
      ? this.substitutionTarget
      : document.getElementById("regular_expression_substitution");

    const data = {};
    if (patternField?.value) data.r = patternField.value;
    if (testField?.value) data.t = testField.value;
    if (optionsField?.value) data.o = optionsField.value;
    if (substitutionField?.value) data.s = substitutionField.value;

    if (Object.keys(data).length === 0) return;

    try {
      const json = JSON.stringify(data);
      const bytes = new TextEncoder().encode(json);
      const binary = String.fromCharCode(...bytes);
      const base64 = btoa(binary);
      const urlSafe = base64
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=/g, "");

      const url = new URL(window.location.origin + window.location.pathname);
      url.searchParams.set("p", urlSafe);

      navigator.clipboard.writeText(url.toString()).then(
        () => this.showTooltip(url.toString()),
        () => prompt("Copy this URL:", url.toString()),
      );
    } catch (e) {
      console.error("Failed to generate permalink:", e);
    }
  }

  showTooltip(url) {
    if (!this.hasButtonTarget) return;

    // Shorten URL for display
    const maxLength = 60;
    let displayUrl = url;
    if (url.length > maxLength) {
      const start = url.substring(0, 35);
      const end = url.substring(url.length - 20);
      displayUrl = `${start}...${end}`;
    }

    // Get localized message from data attribute
    const message = this.buttonTarget.dataset.copiedMessage;
    if (!message) return;

    const tooltip = document.createElement("div");
    tooltip.innerHTML = `${message}<br><span class="font-mono text-xs">${displayUrl}</span>`;
    tooltip.className =
      "absolute top-full mt-2 left-1/2 -translate-x-1/2 bg-gray-800 text-white text-xs px-3 py-2 rounded whitespace-nowrap pointer-events-none shadow-lg border border-gray-700";

    this.buttonTarget.style.position = "relative";
    this.buttonTarget.appendChild(tooltip);

    setTimeout(() => tooltip.remove(), 3000);
  }
}
