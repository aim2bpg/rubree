import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="drag-scroll"
export default class extends Controller {
  connect() {
    this.isDragging = false;
    this.startX = 0;
    this.scrollLeft = 0;

    this.element.style.cursor = "grab";

    this.element.addEventListener("mousedown", this.onMouseDown);
    this.element.addEventListener("mouseleave", this.onMouseLeave);
    this.element.addEventListener("mouseup", this.onMouseUp);
    this.element.addEventListener("mousemove", this.onMouseMove);
  }

  disconnect() {
    this.element.removeEventListener("mousedown", this.onMouseDown);
    this.element.removeEventListener("mouseleave", this.onMouseLeave);
    this.element.removeEventListener("mouseup", this.onMouseUp);
    this.element.removeEventListener("mousemove", this.onMouseMove);
  }

  onMouseDown = (e) => {
    this.isDragging = true;
    this.element.classList.add("cursor-grabbing");
    this.element.classList.remove("cursor-grab");
    document.body.style.userSelect = "none";

    this.startX = e.pageX - this.element.offsetLeft;
    this.scrollLeft = this.element.scrollLeft;
  };

  onMouseLeave = () => {
    this.stopDragging();
  };

  onMouseUp = () => {
    this.stopDragging();
  };

  onMouseMove = (e) => {
    if (!this.isDragging) return;
    e.preventDefault();

    const x = e.pageX - this.element.offsetLeft;
    const walk = (x - this.startX) * 1.5;
    this.element.scrollLeft = this.scrollLeft - walk;
  };

  stopDragging() {
    this.isDragging = false;
    this.element.classList.remove("cursor-grabbing");
    this.element.classList.add("cursor-grab");
    document.body.style.userSelect = "";
  }
}
