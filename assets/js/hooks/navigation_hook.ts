import type { Hook } from "phoenix_live_view";

const bindings = new WeakMap<
  HTMLElement,
  { sync: () => void; destroy: () => void }
>();

// Layout remains CSS-owned. The controller measures only on resize and tracks
// scroll direction locally; no LiveView events or per-scroll geometry reads.
const Navigation: Hook = {
  mounted() {
    const header = this.el;
    const lifetime = new AbortController();
    const { signal } = lifetime;
    let height = header.offsetHeight;
    let topGuard = height;
    let maxScroll = 0;
    let previous = window.scrollY;
    let turn = previous;
    let direction = 0;
    let hidden = false;
    let navigating = false;

    const position = () => Math.max(0, Math.min(window.scrollY, maxScroll));
    const sync = () => {
      header.toggleAttribute("data-hidden", hidden);
      header.toggleAttribute("data-scrolled", position() > topGuard);
    };
    const reset = () => {
      previous = position();
      turn = previous;
      direction = 0;
      hidden = false;
      sync();
    };
    const measure = () => {
      height = header.offsetHeight;
      topGuard =
        height + Number.parseFloat(getComputedStyle(document.body).paddingTop);
      maxScroll = Math.max(
        0,
        document.documentElement.scrollHeight - window.innerHeight,
      );
      reset();
    };
    const scroll = () => {
      const current = position();
      const delta = current - previous;
      previous = current;
      if (
        navigating ||
        header.contains(document.activeElement) ||
        current <= topGuard
      ) {
        reset();
        return;
      }
      const nextDirection = Math.sign(delta);
      if (nextDirection === 0) return;
      if (nextDirection !== direction) {
        direction = nextDirection;
        turn = current - delta;
      }
      // Starting thresholds follow the actual header size: more travel to
      // retreat than to recover. Tune through phone review, not font shrinking.
      const threshold = direction > 0 ? height / 2 : height / 8;
      if (Math.abs(current - turn) >= threshold) hidden = direction > 0;
      sync();
    };

    const observer = new ResizeObserver(measure);
    observer.observe(header);
    observer.observe(document.body);
    window.addEventListener("resize", measure, { signal });
    window.addEventListener("scroll", scroll, { passive: true, signal });
    window.addEventListener("hashchange", reset, { signal });
    window.addEventListener("popstate", reset, { signal });
    window.addEventListener("pageshow", measure, { signal });
    window.addEventListener(
      "phx:page-loading-start",
      () => {
        navigating = true;
        reset();
      },
      { signal },
    );
    window.addEventListener(
      "phx:page-loading-stop",
      () => {
        navigating = false;
        measure();
      },
      { signal },
    );
    header.addEventListener("focusin", reset, { signal });
    header.addEventListener("focusout", reset, { signal });
    measure();
    bindings.set(header, {
      sync,
      destroy() {
        lifetime.abort();
        observer.disconnect();
        header.removeAttribute("data-hidden");
        header.removeAttribute("data-scrolled");
      },
    });
  },
  updated() {
    bindings.get(this.el)?.sync();
  },
  destroyed() {
    bindings.get(this.el)?.destroy();
    bindings.delete(this.el);
  },
};

export default Navigation;
