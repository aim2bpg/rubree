import { Controller } from "@hotwired/stimulus";
import { enableDragScroll } from "./regexp_examples/drag_scroll";

export default class extends Controller {
  static values = {
    horizontalOnly: { type: Boolean, default: false },
  };

  connect() {
    this._dragScrollObj = enableDragScroll(
      this.element,
      this._initialScrollTop || 0,
      { horizontalOnly: this.horizontalOnlyValue },
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
