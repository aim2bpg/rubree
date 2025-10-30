import { Controller } from "@hotwired/stimulus";
import { enableDragScroll } from "./regexp_examples/drag_scroll";

// Connects to data-controller="drag-scroll"
export default class extends Controller {
  connect() {
    // Delegate drag-to-scroll to shared pointer-based implementation.
    this._dragScrollObj = enableDragScroll(
      this.element,
      this._initialScrollTop || 0,
    );
    try {
      this.element.style.cursor = "grab";
    } catch (_e) {}
  }

  disconnect() {
    try {
      if (this._dragScrollObj) this._dragScrollObj.disable();
    } catch (_e) {}
  }
}
