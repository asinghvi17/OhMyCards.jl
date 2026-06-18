(function () {
  // Each gallery is scoped to its own root so multiple galleries on one page
  // do not interfere. The root is the nearest ancestor with class
  // "omc-gallery-root" of the script tag that ran us.
  var scripts = document.querySelectorAll("script[data-omc-gallery]");
  scripts.forEach(function (script) {
    var root = script.closest(".omc-gallery-root");
    if (!root || root.dataset.omcInit === "1") return;
    root.dataset.omcInit = "1";

    var input = root.querySelector(".omc-gallery-search");
    var chips = Array.prototype.slice.call(root.querySelectorAll(".omc-tag-chip"));
    var items = Array.prototype.slice.call(root.querySelectorAll(".grid-item"));
    var empty = root.querySelector(".omc-gallery-empty");
    var active = new Set();

    function norm(s) { return (s || "").toLowerCase(); }

    function apply() {
      var q = norm(input ? input.value : "");
      var shown = 0;
      items.forEach(function (item) {
        var title = norm(item.getAttribute("data-title"));
        var desc = norm(item.getAttribute("data-description"));
        var tags = norm(item.getAttribute("data-tags")).split(",").filter(Boolean);
        var matchText = !q || title.indexOf(q) !== -1 || desc.indexOf(q) !== -1 ||
          tags.some(function (t) { return t.indexOf(q) !== -1; });
        var matchTags = active.size === 0 ||
          Array.from(active).every(function (t) { return tags.indexOf(t) !== -1; });
        var visible = matchText && matchTags;
        item.hidden = !visible;
        if (visible) shown++;
      });
      if (empty) empty.style.display = shown === 0 ? "block" : "none";
    }

    if (input) input.addEventListener("input", apply);
    chips.forEach(function (chip) {
      chip.addEventListener("click", function () {
        var tag = chip.getAttribute("data-tag");
        if (active.has(tag)) { active.delete(tag); chip.setAttribute("aria-pressed", "false"); }
        else { active.add(tag); chip.setAttribute("aria-pressed", "true"); }
        apply();
      });
    });
    apply();
  });
})();
