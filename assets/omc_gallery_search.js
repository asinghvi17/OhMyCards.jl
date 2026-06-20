(function () {
  // Client-side search/tag filtering for OhMyCards VitepressGallery.
  //
  // Loaded as a `<head>` <script src> (see OhMyCardsDocumenterVitepressExt), NOT
  // inlined: a body <script> is HTML-escaped by Vue and never executes; a head
  // script runs normally and survives SPA navigation.
  //
  // Vue re-renders/replaces the gallery DOM (hydration, SPA routes), so we never
  // hold node references: delegate events on `document` and re-query the live DOM
  // on every apply. Active tag state is read live from chips' `aria-pressed`.
  function norm(s) { return (s || "").toLowerCase(); }

  function applyGallery(root) {
    if (!root) return;
    var input = root.querySelector(".omc-gallery-search");
    var empty = root.querySelector(".omc-gallery-empty");
    var q = norm(input ? input.value : "");
    var active = [];
    root.querySelectorAll('.omc-tag-chip[aria-pressed="true"]').forEach(function (c) {
      var t = c.getAttribute("data-tag");
      if (t) active.push(t);
    });
    var shown = 0;
    root.querySelectorAll(".grid-item").forEach(function (item) {
      var title = norm(item.getAttribute("data-title"));
      var desc = norm(item.getAttribute("data-description"));
      var tags = norm(item.getAttribute("data-tags")).split(",").filter(Boolean);
      var matchText = !q || title.indexOf(q) !== -1 || desc.indexOf(q) !== -1 ||
        tags.some(function (t) { return t.indexOf(q) !== -1; });
      var matchTags = active.length === 0 ||
        active.every(function (t) { return tags.indexOf(t) !== -1; });
      var visible = matchText && matchTags;
      item.hidden = !visible;
      if (visible) shown++;
    });
    if (empty) empty.style.display = shown === 0 ? "block" : "none";
  }

  function applyAll() {
    var roots = document.querySelectorAll(".omc-gallery-root");
    for (var i = 0; i < roots.length; i++) applyGallery(roots[i]);
  }

  // Install delegated listeners once per page session; bubbling to `document`
  // survives the gallery DOM being swapped.
  if (!window.__omcGalleryDelegated) {
    window.__omcGalleryDelegated = true;

    document.addEventListener("input", function (e) {
      var t = e.target;
      if (t && t.classList && t.classList.contains("omc-gallery-search")) {
        applyGallery(t.closest(".omc-gallery-root"));
      }
    });

    document.addEventListener("click", function (e) {
      var t = e.target;
      if (t && t.classList && t.classList.contains("omc-tag-chip")) {
        var pressed = t.getAttribute("aria-pressed") === "true";
        t.setAttribute("aria-pressed", pressed ? "false" : "true");
        applyGallery(t.closest(".omc-gallery-root"));
      }
    });

    // Re-apply on back/forward SPA nav (forward nav needs none: fresh DOM is
    // all-visible and the delegated listeners handle interaction).
    window.addEventListener("popstate", applyAll);
  }

  // Head script may run before the gallery/Vue hydration exists, so re-run at
  // each later readiness milestone too. All calls are idempotent.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", applyAll);
  } else {
    applyAll();
  }
  window.addEventListener("load", applyAll);
})();
