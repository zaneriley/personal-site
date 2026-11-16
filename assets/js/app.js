import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

import { initActionLight } from "./action-light";
import { initCloudSurface } from "./cloud-surface";
import NavigationHook from "./hooks/navigation_hook";
import ThemeSwitcherHook from "./hooks/theme_switcher_hook";
import WeatherHook from "./hooks/weather_hook";
import { onDocumentPatch } from "./page-motion";
import { themeController } from "./theme-switcher";

// Define hooks before using them
const Hooks = {
  ThemeSwitcher: ThemeSwitcherHook,
  Weather: WeatherHook,
  Navigation: NavigationHook,
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
  dom: { onDocumentPatch },
});

themeController();
liveSocket.connect();

// Light-mode cloud surface. Static markup in the root layout, outside the
// LiveView tree — initializes once here, not via a hook.
initCloudSurface();
initActionLight();

window.liveSocket = liveSocket;

window.portfolioEasterEgg = () => {
  if (document.querySelector("script[data-portfolio-easter-egg]")) {
    return;
  }

  const script = document.createElement("script");
  script.defer = true;
  script.dataset.portfolioEasterEgg = "true";
  script.src = "/js/console-easter-egg.js";
  document.head.appendChild(script);
};
