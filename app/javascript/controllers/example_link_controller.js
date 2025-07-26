document.addEventListener("DOMContentLoaded", () => {
  const tabs = document.querySelectorAll(".category-tab");
  const sections = document.querySelectorAll(".examples-category");
  const exampleLink = document.getElementById("example-link");
  const rubreeLink = document.getElementById("rubree-link");
  const expressionField = document.getElementById(
    "regular_expression_expression",
  );
  const testStringField = document.getElementById(
    "regular_expression_test_string",
  );
  const optionsField = document.getElementById("regular_expression_options");

  tabs.forEach((tab) => {
    tab.addEventListener("click", (e) => {
      e.preventDefault();

      tabs.forEach((t) => {
        t.classList.remove("bg-gray-700", "text-white");
        t.classList.add("bg-gray-800", "text-gray-300");
      });

      tab.classList.add("bg-gray-700", "text-white");
      tab.classList.remove("bg-gray-800", "text-gray-300");

      const cat = tab.dataset.category;
      sections.forEach((s) => s.classList.add("hidden"));
      document.getElementById(`category-${cat}`).classList.remove("hidden");
    });
  });

  document
    .querySelectorAll(".examples-category .cursor-pointer")
    .forEach((item) => {
      item.addEventListener("click", () => {
        const regex = item.dataset.pattern;
        const testStr = item.dataset.test;
        const options = item.dataset.options;

        if (expressionField && testStringField && optionsField) {
          expressionField.value = regex;
          testStringField.value = testStr;
          optionsField.value = options || "";

          expressionField.dispatchEvent(new Event("input", { bubbles: true }));
          testStringField.dispatchEvent(new Event("input", { bubbles: true }));
          optionsField.dispatchEvent(new Event("input", { bubbles: true }));
        }
      });
    });

  if (exampleLink && expressionField && testStringField && optionsField) {
    exampleLink.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();

      const today = new Date();
      const examplePattern =
        "(?<month>\\d{1,2})\\/(?<day>\\d{1,2})\\/(?<year>\\d{4})";
      const exampleTestString = `Today's date is: ${today.getMonth() + 1}/${today.getDate()}/${today.getFullYear()}.`;

      expressionField.value = examplePattern;
      testStringField.value = exampleTestString;
      optionsField.value = "";

      expressionField.dispatchEvent(new Event("input", { bubbles: true }));
      testStringField.dispatchEvent(new Event("input", { bubbles: true }));
      optionsField.dispatchEvent(new Event("input", { bubbles: true }));
    });
  }

  if (rubreeLink) {
    rubreeLink.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();

      expressionField.value = "";
      testStringField.value = "";
      optionsField.value = "";

      expressionField.dispatchEvent(new Event("input", { bubbles: true }));
      testStringField.dispatchEvent(new Event("input", { bubbles: true }));
      optionsField.dispatchEvent(new Event("input", { bubbles: true }));

      tabs[0]?.click();
    });
  }

  tabs[0]?.click();
});
