// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "./controllers";
import Alpine from "alpinejs";

window.Alpine = Alpine;
Alpine.start();

document.addEventListener("alpine:init", () => {
  Alpine.data("matchComponent", () => ({
    wrap: localStorage.getItem("wrap") !== "false",
    showInvisibles: false,

    init() {
      this.$watch("wrap", (value) => {
        localStorage.setItem("wrap", value);
      });
    },
  }));
});
