import { Controller } from "@hotwired/stimulus";
import { enableDragScroll } from "./regexp_examples/drag_scroll";

export default class extends Controller {
  connect() {
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
