(function () {
  // Client-side search/tag filtering for OhMyCards VitepressGallery.
  //
  // This file is shipped to the Vitepress site's `public/` directory and loaded
  // via a `<head>` <script src> tag (see OhMyCardsDocumenterVitepressExt). It is
  // NOT inlined into the page body: Vitepress renders markdown through Vue, and a
  // <script> embedded in body content is (a) HTML-escaped, mangling JS operators,
  // and (b) inserted via Vue's render, so it never executes. A head <script src>
  // runs normally and persists across SPA navigation.
  //
  // Because the gallery DOM is rendered/replaced by Vue (hydration, SPA route
  // changes), we never capture node references: we DELEGATE events on `document`
  // and re-query the live DOM on every apply, always acting on the nodes that are
  // actually on the page. Active tag state lives in the chips' `aria-pressed`
  // attribute (read live), not a closure Set.
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

  // Install the delegated listeners once per page session. Native `input`/`click`
  // events bubble to `document`, so this survives the gallery DOM being swapped.
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

    // Re-apply on back/forward SPA navigation. (Forward nav into a gallery needs
    // no apply: the freshly-rendered DOM defaults to all-visible with the empty
    // state CSS-hidden, and the delegated listeners handle all interaction.)
    window.addEventListener("popstate", applyAll);
  }

  // Initial pass: the head script may run before the body/gallery exists and
  // before Vue hydration, so re-run at each later readiness milestone too. All
  // calls are idempotent.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", applyAll);
  } else {
    applyAll();
  }
  window.addEventListener("load", applyAll);
})();
