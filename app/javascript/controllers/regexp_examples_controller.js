import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="regexp-examples"
export default class extends Controller {
  static targets = ["tab", "category", "example"];

  connect() {
    if (this.hasTabTarget && this.tabTargets[0]) {
      this.showCategoryByElement(this.tabTargets[0]);
    } else {
      console.warn("⚠️ No tabTargets found");
    }
  }

  showCategory(event) {
    const tab = event.currentTarget;
    this.showCategoryByElement(tab);
  }

  showCategoryByElement(tab) {
    const selected = tab.dataset.category;

    this.tabTargets.forEach((t) => {
      t.classList.toggle("bg-gray-700", t === tab);
      t.classList.toggle("text-white", t === tab);
      t.classList.toggle("bg-gray-800", t !== tab);
      t.classList.toggle("text-gray-300", t !== tab);
    });

    this.categoryTargets.forEach((c) => {
      const match = c.dataset.category === selected;
      c.classList.toggle("hidden", !match);
    });
  }

  selectExample(event) {
    const { pattern, test, options } = event.currentTarget.dataset;

    const patternField = document.getElementById(
      "regular_expression_expression",
    );
    const testField = document.getElementById("regular_expression_test_string");
    const optionsField = document.querySelector(
      'input[name="regular_expression[options]"]',
    );

    if (patternField && testField) {
      patternField.value = pattern;
      testField.value = test;
      if (optionsField) optionsField.value = options || "";

      patternField.dispatchEvent(new Event("input", { bubbles: true }));
      testField.dispatchEvent(new Event("input", { bubbles: true }));
    }
  }
}
