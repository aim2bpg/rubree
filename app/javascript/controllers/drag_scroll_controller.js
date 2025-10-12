import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="drag-scroll"
export default class extends Controller {
  connect() {
    this.isDragging = false;
    this.startX = 0;
    this.startY = 0;
    this.scrollLeft = 0;
    this.scrollTop = 0;

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
    this.startY = e.pageY - this.element.offsetTop;
    this.scrollLeft = this.element.scrollLeft;
    this.scrollTop = this.element.scrollTop;
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
    const y = e.pageY - this.element.offsetTop;

    const walkX = (x - this.startX) * 1.5;
    const walkY = (y - this.startY) * 1.5;

    this.element.scrollLeft = this.scrollLeft - walkX;
    this.element.scrollTop = this.scrollTop - walkY;
  };

  stopDragging() {
    this.isDragging = false;
    this.element.classList.remove("cursor-grabbing");
    this.element.classList.add("cursor-grab");
    document.body.style.userSelect = "";
  }
}
