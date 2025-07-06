// app/javascript/controllers/example_link_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const exampleLink = document.getElementById("example-link");
    const expressionField = document.getElementById(
      "regular_expression_expression",
    );
    const testStringField = document.getElementById(
      "regular_expression_test_string",
    );

    if (!exampleLink || !expressionField || !testStringField) return;

    exampleLink.addEventListener("click", (e) => {
      e.preventDefault();

      const today = new Date();
      const examplePattern =
        "(?<month>\\d{1,2})\\/(?<day>\\d{1,2})\\/(?<year>\\d{4})";
      const exampleTestString = `Today's date is: ${today.getMonth() + 1}/${today.getDate()}/${today.getFullYear()}.`;

      expressionField.value = examplePattern;
      testStringField.value = exampleTestString;

      expressionField.dispatchEvent(new Event("input", { bubbles: true }));
      testStringField.dispatchEvent(new Event("input", { bubbles: true }));
    });
  }
}
