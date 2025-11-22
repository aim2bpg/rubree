import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.boundShowLoading = this.showLoading.bind(this);
    this.boundHideLoading = this.hideLoading.bind(this);
    this.boundHideLoadingOnRender = this.hideLoadingOnRender.bind(this);

    this.element.addEventListener("turbo:submit-start", this.boundShowLoading);
    this.element.addEventListener("turbo:submit-end", this.boundHideLoading);

    // Listen at document level for turbo frame render
    document.addEventListener(
      "turbo:frame-render",
      this.boundHideLoadingOnRender,
    );
  }

  disconnect() {
    this.element.removeEventListener(
      "turbo:submit-start",
      this.boundShowLoading,
    );
    this.element.removeEventListener("turbo:submit-end", this.boundHideLoading);
    document.removeEventListener(
      "turbo:frame-render",
      this.boundHideLoadingOnRender,
    );
  }

  submit() {
    clearTimeout(this.timeout);

    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, 200);
  }

  showLoading() {
    const overlay = document.getElementById("loading-overlay");
    if (overlay) {
      overlay.classList.remove("hidden");
    }
  }

  hideLoading() {
    const overlay = document.getElementById("loading-overlay");
    if (overlay) {
      overlay.classList.add("hidden");
    }
  }

  hideLoadingOnRender(event) {
    if (event.target.id === "regexp") {
      this.hideLoading();
    }
  }
}
