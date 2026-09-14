import type { ViewHook } from "phoenix_live_view";

// Existing glyph poses are authored by the server. Motion never measures fonts
// or gates content; the new observation is readable before this hook runs.
const duration = 240;
const easing = "cubic-bezier(0.2, 0, 0, 1)";

type WeatherHook = ViewHook & {
  previous: Map<string, string>;
  animations: Set<Animation>;
  reduced: MediaQueryList;
  observer?: IntersectionObserver;
  visible: boolean;
  cancelMotion: () => void;
  onVisibility: () => void;
  onMotionPreference: () => void;
};

function digits(el: HTMLElement) {
  return Array.from(el.querySelectorAll<HTMLElement>("[data-place]"));
}

function remember(hook: WeatherHook) {
  hook.previous = new Map(
    digits(hook.el).map((el) => [
      el.dataset.place ?? "",
      el.dataset.digit ?? "",
    ]),
  );
}

export default {
  mounted(this: WeatherHook) {
    this.animations = new Set();
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)");
    this.visible = false;
    this.cancelMotion = () => {
      for (const animation of this.animations) animation.cancel();
      this.animations.clear();
    };
    this.onMotionPreference = () => {
      if (this.reduced.matches) this.cancelMotion();
    };
    this.onVisibility = () => {
      this.cancelMotion();
      if (!document.hidden) this.pushEvent("weather:resume", {});
    };
    this.reduced.addEventListener("change", this.onMotionPreference);
    document.addEventListener("visibilitychange", this.onVisibility);
    if ("IntersectionObserver" in window) {
      this.observer = new IntersectionObserver(([entry]) => {
        this.visible = entry.isIntersecting;
        if (!this.visible) this.cancelMotion();
      });
      this.observer.observe(this.el);
    }
    remember(this);
  },
  beforeUpdate(this: WeatherHook) {
    this.cancelMotion();
    remember(this);
  },
  updated(this: WeatherHook) {
    if (!this.visible || document.hidden || this.reduced.matches) return;
    for (const el of digits(this.el)) {
      if (this.previous.get(el.dataset.place ?? "") === el.dataset.digit)
        continue;
      if (typeof el.animate !== "function") continue;
      const finalPose = el.style.transform;
      const animation = el.animate(
        [
          { transform: `translateY(0.12em) ${finalPose}`, opacity: 0.65 },
          { transform: finalPose, opacity: 1 },
        ],
        { duration, easing },
      );
      this.animations.add(animation);
      animation.onfinish = () => this.animations.delete(animation);
      animation.oncancel = () => this.animations.delete(animation);
    }
  },
  disconnected(this: WeatherHook) {
    this.cancelMotion();
  },
  destroyed(this: WeatherHook) {
    this.cancelMotion();
    this.observer?.disconnect();
    this.reduced.removeEventListener("change", this.onMotionPreference);
    document.removeEventListener("visibilitychange", this.onVisibility);
  },
};
