import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="regexp-form"
export default class extends Controller {
  submit() {
    clearTimeout(this.timeout);

    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, 200);
  }
}
