import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createThemeController } from "../../js/theme-switcher";

let system: EventTarget & { matches: boolean };
let state: ReturnType<typeof createThemeController>;
beforeEach(() => {
  localStorage.clear();
  document.documentElement.dataset.theme = "dark";
  document.head.innerHTML = '<meta name="theme-color" content="#343334">';
  system = Object.assign(new EventTarget(), { matches: true });
  vi.stubGlobal("matchMedia", () => system);
});
afterEach(() => {
  state?.destroy();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe("theme preference", () => {
  it("follows OS until a click, then retains the explicit choice", () => {
    state = createThemeController();
    expect(state.theme).toBe("light");
    system.matches = false;
    system.dispatchEvent(new Event("change"));
    expect(state.theme).toBe("dark");
    state.toggle();
    expect(localStorage.getItem("theme")).toBe("light");
    system.dispatchEvent(new Event("change"));
    expect(state.theme).toBe("light");
  });
  it.each(["system", "garbage", ""])(
    "ignores legacy/invalid preference %s",
    (value) => {
      localStorage.setItem("theme", value);
      state = createThemeController();
      expect(state.theme).toBe("light");
    },
  );
  it("loads an explicit preference before subscribing a control", () => {
    localStorage.setItem("theme", "dark");
    state = createThemeController();
    const listener = vi.fn();
    state.subscribe(listener);
    expect(listener).toHaveBeenCalledWith("dark", false);
    expect(document.documentElement.dataset.theme).toBe("dark");
  });
  it("keeps clicks functional when reading and writing storage throw", () => {
    vi.spyOn(Storage.prototype, "getItem").mockImplementation(() => {
      throw new Error("denied");
    });
    vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new Error("denied");
    });
    state = createThemeController();
    state.toggle();
    expect(state.theme).toBe("dark");
    system.dispatchEvent(new Event("change"));
    expect(state.theme).toBe("dark");
    state.toggle();
    expect(state.theme).toBe("light");
  });
  it("synchronizes another tab and returns to OS when storage is cleared", () => {
    state = createThemeController();
    window.dispatchEvent(
      new StorageEvent("storage", {
        key: "theme",
        newValue: "dark",
        storageArea: localStorage,
      }),
    );
    expect(state.theme).toBe("dark");
    window.dispatchEvent(
      new StorageEvent("storage", {
        key: null,
        newValue: null,
        storageArea: localStorage,
      }),
    );
    expect(state.theme).toBe("light");
    window.dispatchEvent(
      new StorageEvent("storage", {
        key: "theme",
        newValue: "dark",
        storageArea: sessionStorage,
      }),
    );
    expect(state.theme).toBe("light");
  });
  it("unsubscribes removed controls and tears down global listeners", () => {
    state = createThemeController();
    const listener = vi.fn();
    const unsubscribe = state.subscribe(listener);
    unsubscribe();
    state.toggle();
    expect(listener).toHaveBeenCalledTimes(1);
    state.destroy();
    window.dispatchEvent(
      new StorageEvent("storage", { key: "theme", newValue: "light" }),
    );
    expect(state.theme).toBe("dark");
  });
});
