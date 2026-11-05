import type { Hook } from "phoenix_live_view";

const bindings = new WeakMap<
  HTMLElement,
  { sync: () => void; destroy: () => void }
>();

// Layout remains CSS-owned. The header is sticky and always shown; this hook
// only marks when the page has scrolled past it, so it gains a panel
// background. The guard is measured on resize, not on every scroll.
const Navigation: Hook = {
  mounted() {
    const header = this.el;
    const lifetime = new AbortController();
    const { signal } = lifetime;
    let topGuard = 0;

    const sync = () => {
      header.toggleAttribute("data-scrolled", window.scrollY > topGuard);
    };
    const measure = () => {
      topGuard =
        header.offsetHeight +
        Number.parseFloat(getComputedStyle(document.body).paddingTop);
      sync();
    };

    const observer = new ResizeObserver(measure);
    observer.observe(header);
    observer.observe(document.body);
    window.addEventListener("scroll", sync, { passive: true, signal });
    window.addEventListener("pageshow", measure, { signal });
    measure();
    bindings.set(header, {
      sync,
      destroy() {
        lifetime.abort();
        observer.disconnect();
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
