import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="regexp-examples"
export default class extends Controller {
  static targets = [
    "tab",
    "category",
    "example",
    "pattern",
    "test",
    "options",
    "substitution",
  ];

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
    const { pattern, test, options, substitution } =
      event.currentTarget.dataset;

    if (this.hasPatternTarget && this.hasTestTarget) {
      this.patternTarget.value = pattern;
      this.testTarget.value = test;

      if (this.hasOptionsTarget) {
        this.optionsTarget.value = options || "";
      }

      if (this.hasSubstitutionTarget) {
        this.substitutionTarget.value = substitution || "";
      }

      // Trigger input events
      this.patternTarget.dispatchEvent(new Event("input", { bubbles: true }));
      this.testTarget.dispatchEvent(new Event("input", { bubbles: true }));

      if (this.hasSubstitutionTarget) {
        this.substitutionTarget.dispatchEvent(
          new Event("input", { bubbles: true }),
        );
      }
    } else {
      console.warn("⚠️ Pattern or Test target not found");
    }
  }
}
