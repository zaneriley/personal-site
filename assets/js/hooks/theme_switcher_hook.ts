import type { Hook } from "phoenix_live_view";
import { createSunMoonMotion } from "../sun-moon-motion";
import { themeController } from "../theme-switcher";

const bindings = new WeakMap<
  HTMLElement,
  { destroy: () => void; sync: () => void }
>();
const ThemeSwitcher: Hook = {
  mounted() {
    const button = this.el as HTMLButtonElement;
    const state = themeController();
    const motion = createSunMoonMotion(button);
    const sync = () => {
      button.dataset.ready = "";
      button.setAttribute("aria-pressed", String(state.theme === "dark"));
    };
    const unsubscribe = state.subscribe((theme, animate) => {
      sync();
      motion.set(theme === "dark", animate);
    });
    const click = (event: MouseEvent) =>
      state.toggle(
        event.detail !== 0 &&
          !matchMedia("(prefers-reduced-motion: reduce)").matches,
      );
    button.addEventListener("click", click);
    button.dataset.ready = "";
    bindings.set(button, {
      sync,
      destroy() {
        button.removeEventListener("click", click);
        unsubscribe();
        motion.destroy();
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
export default ThemeSwitcher;
