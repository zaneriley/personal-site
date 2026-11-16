// Page-to-page motion. The choreography and timing live in
// assets/css/_motion.css; this file decides which relation a navigation is
// and moves <html data-phase> through three steps:
//   out   on the tap, the old page leaves while the server answers
//   hold  the new page is swapped in and scrolled to the top, unseen
//   in    once it has painted, the new page arrives
// The live page itself is animated; there are no snapshots to swap back.
//
// LiveView calls onDocumentPatch for every patch (weather, forms, the theme),
// so only the patch that follows a live navigation is held for the exit.

const root = document.documentElement;
const reduced = matchMedia("(prefers-reduced-motion: reduce)");
let here = location.pathname;
let pending: string | null = null;
let pop = false;
let loading = 0;
let turn = 0;
let exit: Promise<void> | null = null;
let queue: Promise<void> | null = null;

const ms = (token: string) =>
  Number.parseFloat(getComputedStyle(root).getPropertyValue(token));
const wait = (time: number) =>
  new Promise<void>((done) => setTimeout(done, time));
// Two frames: the swapped-in page is painted (unseen) before it animates.
// Without this a tall page's first frames are skipped and it pops in.
const painted = () =>
  new Promise<void>((done) =>
    requestAnimationFrame(() => requestAnimationFrame(() => done())),
  );

// TEMP diagnostic (remove before merge): reports what the transition did on
// a real phone as a request the dev server logs.
const report = (data: Record<string, unknown>) => {
  const query = new URLSearchParams(
    Object.entries(data).map(([key, value]) => [key, String(value)]),
  );
  fetch(`/__vt?${query}`).catch(() => {});
};

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
        else {
          // A finger is down for a moment before the click.
          const link = document.querySelector<HTMLElement>(step);
          link?.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }));
          setTimeout(() => link?.click(), 90);
        }
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

// A finger going down on a link readies the page's layers (will-change, in
// _motion.css), so the exit's first frames are painted, not skipped.
document.addEventListener(
  "pointerdown",
  (event) => {
    if (!(event.target as Element).closest?.("a[data-phx-link]")) return;
    root.dataset.nav ??= "";
    const mine = turn;
    wait(1000).then(() => {
      if (turn === mine && !root.dataset.phase) delete root.dataset.nav;
    });
  },
  { passive: true },
);

// Live navigations announce themselves here, more than once each. Back and
// forward only send phx:navigate (no page-loading event), so both are
// handled. The old page starts leaving now, before the server replies.
const leave = (href: string, isPop: boolean) => {
  const to = new URL(href, location.href).pathname;
  if (to === pending) return;
  root.classList.remove("first-paint");
  pending = to;
  pop = isPop;
  report({ step: "leave", to, pop: isPop });
  if (to === here) return;
  turn++;
  root.dataset.nav = relation(here, to);
  root.dataset.phase = "out";
  exit = wait(ms("--motion-leave"));
};

// The page (new, or the old one if nothing arrived) eases in, then the
// attributes go so nothing is left animating. A newer page change takes
// over the attributes; this one then leaves them alone.
const settle = () => {
  const mine = turn;
  root.dataset.phase = "in";
  return wait(ms("--motion-base")).then(() => {
    if (turn !== mine) return;
    delete root.dataset.phase;
    delete root.dataset.nav;
  });
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
  // Never leave a page hidden: if loading ended and no page arrived (a
  // failed or cancelled navigation), bring the old one back.
  const mine = turn;
  wait(ms("--motion-travel")).then(() => {
    if (turn === mine && root.dataset.phase === "out" && !queue) {
      pending = null;
      settle();
    }
  });
});

// The nav marker slides from where it was to where it now is.
const marker = () => document.querySelector<HTMLElement>(".nav-marker");

const arrive = async (start: () => void) => {
  const mine = turn;
  root.dataset.phase = "hold";
  // A new page starts at the top. Nothing is showing at this point, so the
  // jump is never seen. Back and forward keep the position LiveView restores.
  if (!pop) window.scrollTo(0, 0);
  const from = marker()?.getBoundingClientRect();
  try {
    start();
  } finally {
    report({ step: "in", nav: root.dataset.nav, scroll: Math.round(scrollY) });
  }
  const to = marker()?.getBoundingClientRect();
  if (from && to && !reduced.matches) {
    marker()?.animate(
      {
        transformOrigin: ["0 0", "0 0"],
        transform: [
          `translateX(${from.x - to.x}px) scaleX(${from.width / to.width})`,
          "none",
        ],
      },
      { duration: ms("--motion-travel"), easing: "cubic-bezier(0.4, 0, 0.2, 1)" },
    );
  }
  await painted();
  if (turn === mine) await settle();
};

export const onDocumentPatch = (start: () => void) => {
  const to = pending;
  if (!to || to === here) {
    pending = null;
    // Patches apply in order: one that lands during a page change waits
    // its turn behind it.
    if (queue) queue = queue.then(start);
    else start();
    return;
  }
  pending = null;
  here = to;
  const mine = (queue = (exit ?? Promise.resolve())
    .then(() => arrive(start))
    .catch(() => {})
    .finally(() => {
      if (queue === mine) queue = null;
    }));
  exit = null;
};
