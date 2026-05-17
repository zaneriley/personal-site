import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "topbar";

import ThemeSwitcherHook from "./hooks/theme_switcher_hook";

// Define hooks before using them
const Hooks = {
  ThemeSwitcher: ThemeSwitcherHook,
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

// Topbar loader during page loading
topbar.config({
  barColors: { 0: "#C4FB50" },
  shadowColor: "rgba(0, 0, 0, .3)",
});

let topBarScheduled;
window.addEventListener("phx:page-loading-start", () => {
  if (!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 200);
  }
});
window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

// Page transition animations
window.addEventListener("phx:page-loading-start", (info) => {
  if (info.detail.kind === "redirect") {
    document
      .querySelector("[data-main-view]")
      ?.classList.add("phx-page-loading");
  }
});

window.addEventListener("phx:page-loading-stop", () => {
  document
    .querySelector("[data-main-view]")
    ?.classList.remove("phx-page-loading");
});

liveSocket.connect();

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
