// Page-to-page motion. The choreography and timing live in
// assets/css/_motion.css; this file decides which relation a navigation is.
//
// LiveView calls onDocumentPatch for every patch (weather, forms, the theme),
// so only the patch that follows a live navigation runs as a view transition.

const root = document.documentElement;
const reduced = matchMedia("(prefers-reduced-motion: reduce)");
let here = location.pathname;
let pending: string | null = null;
let pop = false;
let loading = 0;

// TEMP diagnostic (remove before merge): reports what the transition did on
// a real phone as a request the dev server logs.
const report = (data: Record<string, unknown>) => {
  const query = new URLSearchParams(
    Object.entries(data).map(([key, value]) => [key, String(value)]),
  );
  fetch(`/__vt?${query}`).catch(() => {});
};
const size = () =>
  `${innerWidth}x${innerHeight}/${Math.round(visualViewport?.width ?? 0)}x${Math.round(visualViewport?.height ?? 0)}`;

// TEMP diagnostic (remove before merge): scripted taps for recording, e.g.
// /en#tap=a[href="/en/work"]|scroll:600|a[href="/en/work/oddity"]|back
// One step every 3 s, starting 4 s after load.
decodeURIComponent(location.hash)
  .match(/^#tap=(.*)/)?.[1]
  .split("|")
  .forEach((step, index) => {
    setTimeout(
      () => {
        if (step === "back") history.back();
        else if (step.startsWith("scroll:")) scrollTo(0, Number(step.slice(7)));
        else document.querySelector<HTMLElement>(step)?.click();
      },
      4000 + index * 3000,
    );
  });

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
  // Into, out of or between detail pages the page fades in place; between
  // sections it also steps sideways in the nav's direction.
  if (b.detail || (a.detail && a.index === b.index)) return "fade";
  return b.index < a.index ? "across-back" : "across-forward";
};

// Live navigations announce themselves here. Back and forward only send
// phx:navigate (no page-loading event), so both are handled.
const leave = (href: string, isPop: boolean) => {
  root.classList.remove("first-paint");
  pending = new URL(href, location.href).pathname;
  pop = isPop;
  report({ step: "leave", to: pending, pop: isPop });
};

// The loading bar (styled in _motion.css) shows only when a page is slow.
window.addEventListener("phx:page-loading-start", (event) => {
  const { kind, to } = (event as CustomEvent).detail;
  if (kind === "redirect") leave(to, false);
  loading ||= window.setTimeout(() => root.classList.add("is-loading"), 200);
});

window.addEventListener("phx:navigate", (event) => {
  const { href, patch, pop: isPop } = (event as CustomEvent).detail;
  if (!patch) leave(href, !!isPop);
});

window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(loading);
  loading = 0;
  root.classList.remove("is-loading");
});

export const onDocumentPatch = (start: () => void) => {
  const to = pending;
  pending = null;
  if (!to || to === here || !document.startViewTransition) {
    if (to) {
      report({ step: "plain", to, same: to === here, vt: !!document.startViewTransition });
      here = to;
    }
    return start();
  }

  const nav = relation(here, to);
  here = to;
  root.dataset.nav = nav;
  const t0 = performance.now();
  const before = size();
  let resized = 0;
  // A browser whose toolbar resizes the screen mid-transition (Firefox on
  // iOS, when the page was scrolled) makes the engine drop the transition.
  // Fade the new page in ourselves so it is never a hard cut.
  const onResize = () => {
    if (resized++) return;
    document.querySelector("[data-main-view]")?.animate(
      { opacity: [0, 1] },
      {
        duration: Number.parseFloat(
          getComputedStyle(root).getPropertyValue("--motion-base"),
        ),
        easing: "cubic-bezier(0.4, 0, 0.2, 1)",
      },
    );
  };
  addEventListener("resize", onResize);
  visualViewport?.addEventListener("resize", onResize);
  const facts = () => ({
    nav,
    resized,
    reduced: reduced.matches,
    ms: Math.round(performance.now() - t0),
    before,
    after: size(),
    scroll: Math.round(scrollY),
    ua: navigator.userAgent.replace(/^.*?\) /, ""),
  });
  const transition = document.startViewTransition(() => {
    start();
    // A new page starts at the top. Do it now, inside the transition, so the
    // new snapshot is taken where the page will actually sit. Back and
    // forward keep the position LiveView restores.
    if (!pop) window.scrollTo(0, 0);
  });
  transition.ready.then(
    () => report({ step: "ready", ...facts() }),
    (error) => report({ step: "skipped", why: `${error.name}: ${error.message}`, ...facts() }),
  );
  transition.finished.finally(() => {
    report({ step: "finished", ...facts() });
    removeEventListener("resize", onResize);
    visualViewport?.removeEventListener("resize", onResize);
    setTimeout(() => report({ step: "settled", after: size() }), 500);
    delete root.dataset.nav;
  });
};
