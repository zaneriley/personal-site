export type Theme = "light" | "dark";
type Listener = (theme: Theme, animate: boolean) => void;
const preference = (value: string | null): Theme | null =>
  value === "light" || value === "dark" ? value : null;

/** Document-lifetime state. Persistence is optional; applying a choice isn't. */
export function createThemeController() {
  const root = document.documentElement;
  const system = window.matchMedia("(prefers-color-scheme: light)");
  let choice: Theme | null = null;
  try {
    choice = preference(localStorage.getItem("theme"));
  } catch {}
  let current: Theme = choice ?? (system.matches ? "light" : "dark");
  const listeners = new Set<Listener>();
  function apply(animate = false) {
    current = choice ?? (system.matches ? "light" : "dark");
    root.dataset.themeMotion = animate ? "animate" : "instant";
    root.dataset.theme = current;
    document
      .querySelector('meta[name="theme-color"]')
      ?.setAttribute("content", current === "dark" ? "#343334" : "#b9ebff");
    for (const listener of listeners) listener(current, animate);
  }
  const onSystem = () => {
    if (choice === null) apply();
  };
  const onStorage = (event: StorageEvent) => {
    if (event.key !== "theme" && event.key !== null) return;
    try {
      if (event.storageArea && event.storageArea !== localStorage) return;
    } catch {
      return;
    }
    choice = preference(event.newValue);
    apply();
  };
  system.addEventListener("change", onSystem);
  window.addEventListener("storage", onStorage);
  apply();
  return {
    get theme() {
      return current;
    },
    toggle(animate = false) {
      choice = current === "dark" ? "light" : "dark";
      apply(animate);
      try {
        localStorage.setItem("theme", choice);
      } catch {}
    },
    subscribe(listener: Listener) {
      listeners.add(listener);
      listener(current, false);
      return () => {
        listeners.delete(listener);
      };
    },
    destroy() {
      system.removeEventListener("change", onSystem);
      window.removeEventListener("storage", onStorage);
      listeners.clear();
    },
  };
}
let controller: ReturnType<typeof createThemeController> | undefined;
export function themeController() {
  controller ??= createThemeController();
  return controller;
}
