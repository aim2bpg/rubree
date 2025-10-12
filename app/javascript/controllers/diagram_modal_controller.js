import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "content", "source"];

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
}
