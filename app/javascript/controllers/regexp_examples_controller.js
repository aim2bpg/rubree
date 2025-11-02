import { Controller } from "@hotwired/stimulus";
import * as HeaderDropdownCtrl from "./regexp_examples/controller_header_dropdown";
import * as ModalCtrl from "./regexp_examples/controller_modal";
import * as SelectionCtrl from "./regexp_examples/controller_selection";

export default class extends Controller {
  static targets = [
    "tab",
    "category",
    "example",
    "pattern",
    "test",
    "options",
    "substitution",
    "modal",
    "modalContent",
    "modalResult",
    "exampleSelect",
    "caretButton",
    "diceButton",
    "headerDropdown",
    "headerScroll",
    "hoverCategory",
    "filter",
    "root",
  ];

  connect() {
    if (this.hasTabTarget && this.tabTargets[0]) {
      this.showCategoryByElement(this.tabTargets[0]);
    }

    this._boundEsc = this._onEsc.bind(this);
    this._focusHandler = null;
    this._previousActive = null;
    this._observer = null;
    this._modalResultObserver = null;
    this._movedForm = null;

    this._selectElements = Array.from(
      document.querySelectorAll(
        '[data-regexp-examples-target="exampleSelect"]',
      ),
    );
    this._selectHandler = this.selectFromSelect.bind(this);
    this._selectElements.forEach((sel) => {
      sel.addEventListener("change", this._selectHandler);
    });
    this._primarySelect =
      document.getElementById("examples-select-header") ||
      this._selectElements?.[0] ||
      null;

    this._primarySelectFocusHandler = () => this._setCaretOpen(true);
    this._primarySelectBlurHandler = () => this._setCaretOpen(false);
    if (this._primarySelect) {
      this._primarySelect.addEventListener(
        "focus",
        this._primarySelectFocusHandler,
      );
      this._primarySelect.addEventListener(
        "blur",
        this._primarySelectBlurHandler,
      );
    }
    this._diceTimeout = null;
    this._headerOpen = false;
    this._outsideClickHandler = null;
    this._dropdownKeyHandler = this._onDropdownKeydown.bind(this);
    this._repositionHandler = null;
    this._headerScrollTop = 0;
    this._lastSelectedElement = null;
    this._lastSelectedIndex = null;
    this._lastSelectedClass = "border-l-4 border-blue-400 pl-4";
  }

  disconnect() {
    if (this._observer) this._observer.disconnect();
    document.removeEventListener("keydown", this._boundEsc);
    if (
      this._selectHandler &&
      this._selectElements &&
      this._selectElements.length
    ) {
      this._selectElements.forEach((sel) => {
        sel.removeEventListener("change", this._selectHandler);
      });
    }
    try {
      if (this._primarySelect) {
        this._primarySelect.removeEventListener(
          "focus",
          this._primarySelectFocusHandler,
        );
        this._primarySelect.removeEventListener(
          "blur",
          this._primarySelectBlurHandler,
        );
      }
    } catch (_e) {}
    if (this._diceTimeout) {
      clearTimeout(this._diceTimeout);
      this._diceTimeout = null;
    }

    try {
      if (this._outsideClickHandler)
        document.removeEventListener("click", this._outsideClickHandler, true);
      document.removeEventListener("keydown", this._boundHeaderEsc);
    } catch (_e) {}
  }

  _applyLastSelectedClass(el) {
    return SelectionCtrl.applyLastSelectedClass(this, el);
  }

  _removeLastSelectedClass(el) {
    return SelectionCtrl.removeLastSelectedClass(this, el);
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
    return SelectionCtrl.selectExample(this, event);
  }

  openModal(event) {
    return ModalCtrl.openModal(this, event);
  }

  closeModal(event) {
    return ModalCtrl.closeModal(this, event);
  }

  _onEsc(e) {
    return ModalCtrl.onEsc(this, e);
  }

  _restoreForm() {
    return ModalCtrl.restoreForm(this);
  }

  selectFromSelect(e) {
    return SelectionCtrl.selectFromSelect(this, e);
  }

  nextExample(_event) {
    return SelectionCtrl.nextExample(this, _event);
  }

  prevExample(_event) {
    return SelectionCtrl.prevExample(this, _event);
  }

  tryExample(_event) {
    return SelectionCtrl.tryExample(this, _event);
  }

  focusPrimarySelect(e) {
    return SelectionCtrl.focusPrimarySelect(this, e);
  }

  toggleHeaderDropdown(e) {
    return HeaderDropdownCtrl.toggleHeaderDropdown(this, e);
  }

  _openHeaderDropdown() {
    return HeaderDropdownCtrl._openHeaderDropdown(this);
  }

  _closeHeaderDropdown() {
    return HeaderDropdownCtrl._closeHeaderDropdown(this);
  }

  _positionHeaderDropdown() {
    return HeaderDropdownCtrl._positionHeaderDropdown(this);
  }

  _onDropdownKeydown(e) {
    return HeaderDropdownCtrl._onDropdownKeydown(this, e);
  }

  showExampleCategory(e) {
    return HeaderDropdownCtrl.showExampleCategory(this, e);
  }

  clearExampleCategory(_e) {
    return HeaderDropdownCtrl.clearExampleCategory(this);
  }

  _setLastSelectedIndex(itemOrIdx) {
    return SelectionCtrl.setLastSelectedIndex(this, itemOrIdx);
  }

  _enableDragScroll() {
    return HeaderDropdownCtrl._enableDragScroll(this);
  }

  _disableDragScroll() {
    return HeaderDropdownCtrl._disableDragScroll(this);
  }

  _setCaretOpen(open) {
    return HeaderDropdownCtrl._setCaretOpen(this, open);
  }

  filterExamples(e) {
    return SelectionCtrl.filterExamples(this, e);
  }

  trapFocus(modal) {
    return ModalCtrl.trapFocus(this, modal);
  }

  _startResultObserver() {
    return ModalCtrl.startResultObserver(this);
  }

  _updateModalResult() {
    return ModalCtrl.updateModalResult(this);
  }
}
