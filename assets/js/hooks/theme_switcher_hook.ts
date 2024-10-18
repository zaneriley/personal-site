import type { Hook } from "phoenix_live_view";
import { initThemeToggle } from "../theme-switcher";

const ThemeSwitcher: Hook = {
  mounted() {
    initThemeToggle();
  },
  updated() {
    initThemeToggle();
  },
};

export default ThemeSwitcher;
