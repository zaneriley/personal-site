// Page-to-page motion. The choreography and timing live in
// assets/css/_motion.css; this file decides which relation a navigation is
// and names the one shape that travels.
//
// LiveView calls onDocumentPatch for every patch (weather, forms, the theme),
// so only the patch that follows a live navigation runs as a view transition.

const root = document.documentElement;
const reduced = matchMedia("(prefers-reduced-motion: reduce)");
let here = location.pathname;
let pending: string | null = null;
let source: HTMLElement | null = null;

// Site position: section index in nav order, and whether it's a detail page.
const place = (path: string) => {
  const [section = "", slug] = path.split("/").filter(Boolean).slice(1);
  const index = ["", "work", "notes", "about"].indexOf(
    section === "note" ? "notes" : section,
  );
  return {
    index,
    detail: section === "note" || (section === "work" && !!slug),
  };
};

const relation = (from: string, to: string) => {
  const a = place(from);
  const b = place(to);
  if (b.detail) return a.detail ? "next" : "down";
  if (a.detail && a.index === b.index) return "up";
  return b.index < a.index ? "across-back" : "across-forward";
};

const nameOf = (el: Element | null) =>
  (el as HTMLElement | null)?.dataset.vtHero || "";

document.addEventListener("click", (event) => {
  const link = (event.target as Element).closest?.("a[data-phx-link]");
  source = link?.querySelector<HTMLElement>("[data-vt-hero]") ?? null;
});

// Live navigations announce themselves here. Back and forward only send
// phx:navigate (no page-loading event), so both are handled.
const leave = (href: string) => {
  root.classList.remove("first-paint");
  pending = new URL(href, location.href).pathname;
  if (pending !== here) root.classList.add("is-leaving");
};

window.addEventListener("phx:page-loading-start", (event) => {
  const { kind, to } = (event as CustomEvent).detail;
  if (kind === "redirect") leave(to);
});

window.addEventListener("phx:navigate", (event) => {
  const { href, patch } = (event as CustomEvent).detail;
  if (!patch) leave(href);
});

window.addEventListener("phx:page-loading-stop", () => {
  root.classList.remove("is-leaving");
});

export const onDocumentPatch = (start: () => void) => {
  const to = pending;
  pending = null;
  if (!to || to === here || !document.startViewTransition) {
    if (to) here = to;
    return start();
  }

  const nav = relation(here, to);
  here = to;
  const hero = document.querySelector<HTMLElement>(".cs-hero");
  const heroName = hero?.style.getPropertyValue("--vt-hero").trim() || "";
  const travel = !reduced.matches;

  // Only one shape travels: the tapped image going down, or the hero
  // closing back into its card going up. Anything else fades with the page.
  if (hero && nav !== "up") hero.style.viewTransitionName = "none";
  if (travel && source && nav !== "up") {
    source.style.viewTransitionName = nameOf(source);
  }

  root.dataset.nav = nav;
  const transition = document.startViewTransition(() => {
    start();
    root.classList.remove("is-leaving");
    if (travel && nav === "up" && heroName) {
      const card = document.querySelector<HTMLElement>(
        `[data-vt-hero="${heroName}"]`,
      );
      if (card) card.style.viewTransitionName = heroName;
    }
  });
  transition.finished.finally(() => {
    delete root.dataset.nav;
    for (const el of document.querySelectorAll<HTMLElement>("[data-vt-hero]")) {
      el.style.viewTransitionName = "";
    }
    source = null;
  });
};
