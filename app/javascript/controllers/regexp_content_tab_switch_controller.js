import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="content-tab-switch"
export default class extends Controller {
  static targets = [
    "tabReference",
    "tabExamples",
    "referencePanel",
    "examplesPanel",
  ];

  connect() {
    this.showReference();
  }

  showReference() {
    this.referencePanelTarget.classList.remove("hidden");
    this.examplesPanelTarget.classList.add("hidden");
    this.tabReferenceTarget.classList.add("bg-gray-700", "text-white");
    this.tabReferenceTarget.classList.remove("bg-gray-800", "text-gray-300");
    this.tabExamplesTarget.classList.remove("bg-gray-700", "text-white");
    this.tabExamplesTarget.classList.add("bg-gray-800", "text-gray-300");
  }

  showExamples() {
    this.referencePanelTarget.classList.add("hidden");
    this.examplesPanelTarget.classList.remove("hidden");
    this.tabExamplesTarget.classList.add("bg-gray-700", "text-white");
    this.tabExamplesTarget.classList.remove("bg-gray-800", "text-gray-300");
    this.tabReferenceTarget.classList.remove("bg-gray-700", "text-white");
    this.tabReferenceTarget.classList.add("bg-gray-800", "text-gray-300");
  }
}
