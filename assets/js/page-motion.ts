// Page-to-page motion. See assets/css/_motion.css for the timing and the
// rule ("what you tap becomes the next page").
//
// LiveView calls onDocumentPatch for every patch (weather, forms, the
// theme), so only a patch that follows a live navigation runs inside a view
// transition. The tap itself is answered at once with .is-leaving, so the
// page moves before the server replies; the loading bar still reports the
// network if the reply is slow.

const root = document.documentElement;
let navigating = false;
let named: HTMLElement[] = [];

const clearNames = () => {
  for (const el of named) el.style.viewTransitionName = "";
  named = [];
};

// Name the tapped link's shared elements so they morph into the next page.
document.addEventListener("click", (event) => {
  const link = (event.target as Element).closest?.("a[data-phx-link]");
  if (!link || matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  clearNames();
  for (const el of link.querySelectorAll<HTMLElement>(
    "[data-vt-hero], [data-vt-title]",
  )) {
    el.style.viewTransitionName = el.dataset.vtHero || el.dataset.vtTitle || "";
    named.push(el);
  }
});

window.addEventListener("phx:page-loading-start", (event) => {
  if ((event as CustomEvent).detail.kind !== "redirect") return;
  navigating = true;
  root.classList.add("is-leaving");
});

window.addEventListener("phx:page-loading-stop", () => {
  root.classList.remove("is-leaving");
});

export const onDocumentPatch = (start: () => void) => {
  if (!navigating || !document.startViewTransition) return start();
  navigating = false;
  document.startViewTransition(() => {
    start();
    root.classList.remove("is-leaving");
    clearNames();
  });
};
