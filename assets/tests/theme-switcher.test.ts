import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { initThemeToggle } from "../js/theme-switcher.ts";

describe("Theme Toggle Module", () => {
  let originalMatchMedia: typeof window.matchMedia;
  let originalLocalStorage: Storage;

  beforeEach(() => {
    originalMatchMedia = window.matchMedia;
    originalLocalStorage = window.localStorage;

    document.documentElement.removeAttribute("data-theme");
    localStorage.clear();

    // Create the theme switcher form with radio buttons
    document.body.innerHTML = `
      <form id="theme-switcher-form">
        <label>
          <input type="radio" name="theme" value="light">
          Light
        </label>
        <label>
          <input type="radio" name="theme" value="dark">
          Dark
        </label>
        <label>
          <input type="radio" name="theme" value="system">
          System
        </label>
      </form>
    `;
  });

  afterEach(() => {
    window.matchMedia = originalMatchMedia;

    // Reassign localStorage for the tests that might have set it to null
    Object.defineProperty(window, "localStorage", {
      value: originalLocalStorage,
      writable: true,
    });

    document.body.innerHTML = "";

    document.documentElement.removeAttribute("data-theme");
    localStorage.clear();
  });

  it("applies user preference from localStorage on load", () => {
    // Arrange
    localStorage.setItem("theme", "dark");

    // Act
    initThemeToggle();

    // Assert
    expect(document.documentElement.getAttribute("data-theme")).toBe("dark");
  });

  it("defaults to system preference when no user preference is stored", () => {
    // Arrange
    // Simulate system preference for dark mode.
    window.matchMedia = (query: string) => ({
      matches: true,
      media: query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false,
    });

    // Act
    initThemeToggle();

    // Assert
    expect(document.documentElement.getAttribute("data-theme")).toBe("dark");
  });

  it("applies light theme when system preference is light and no user preference is stored", () => {
    // Arrange
    // Simulate system preference for light mode.
    window.matchMedia = (query: string) => ({
      matches: query === "(prefers-color-scheme: light)",
      media: query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false,
    });

    // Act
    initThemeToggle();

    // Assert
    expect(document.documentElement.getAttribute("data-theme")).toBe("light");
  });

  it("overrides system preference with user preference on load", () => {
    // Arrange
    localStorage.setItem("theme", "light");

    // Simulate system preference for dark mode.
    window.matchMedia = (query: string) => ({
      matches: true,
      media: query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false,
    });

    // Act
    initThemeToggle();

    // Assert
    expect(document.documentElement.getAttribute("data-theme")).toBe("light");
  });

  it("updates theme when system preference changes and no user preference is stored", () => {
    // Arrange
    let matchMediaListeners: Array<(e: MediaQueryListEvent) => void> = [];

    let isDarkMode = false; // Initial system preference is light.

    window.matchMedia = (query: string): MediaQueryList => ({
      matches:
        query === "(prefers-color-scheme: dark)" ? isDarkMode : !isDarkMode,
      media: query,
      onchange: null,
      addListener: (listener: (e: MediaQueryListEvent) => void) => {
        matchMediaListeners.push(listener);
      },
      removeListener: (listener: (e: MediaQueryListEvent) => void) => {
        matchMediaListeners = matchMediaListeners.filter((l) => l !== listener);
      },
      addEventListener: (
        type: string,
        listener: (e: MediaQueryListEvent) => void,
      ) => {
        if (type === "change") {
          matchMediaListeners.push(listener);
        }
      },
      removeEventListener: (
        type: string,
        listener: (e: MediaQueryListEvent) => void,
      ) => {
        if (type === "change") {
          matchMediaListeners = matchMediaListeners.filter(
            (l) => l !== listener,
          );
        }
      },
      dispatchEvent: () => false,
    });

    // Act
    initThemeToggle();

    // Assert initial state
    expect(document.documentElement.getAttribute("data-theme")).toBe("light");

    // Simulate system preference change to dark mode.
    isDarkMode = true; // System preference changes to dark mode.
    for (const listener of matchMediaListeners) {
      listener({ matches: true } as MediaQueryListEvent);
    }

    // Assert
    expect(document.documentElement.getAttribute("data-theme")).toBe("dark");
  });

  it("does not update theme when system preference changes and user preference is stored", () => {
    // Arrange
    localStorage.setItem("theme", "light");

    let matchMediaListeners: Array<(e: MediaQueryListEvent) => void> = [];

    let matches = false; // Initial system preference is light.

    window.matchMedia = (query: string) => ({
      matches,
      media: query,
      onchange: null,
      addListener: (listener: (e: MediaQueryListEvent) => void) => {
        matchMediaListeners.push(listener);
      },
      removeListener: (listener: (e: MediaQueryListEvent) => void) => {
        matchMediaListeners = matchMediaListeners.filter((l) => l !== listener);
      },
      addEventListener: (
        type: string,
        listener: (e: MediaQueryListEvent) => void,
      ) => {
        if (type === "change") {
          matchMediaListeners.push(listener);
        }
      },
      removeEventListener: (
        type: string,
        listener: (e: MediaQueryListEvent) => void,
      ) => {
        if (type === "change") {
          matchMediaListeners = matchMediaListeners.filter(
            (l) => l !== listener,
          );
        }
      },
      dispatchEvent: () => false,
    });

    // Act
    initThemeToggle();

    // Assert initial state
    expect(document.documentElement.getAttribute("data-theme")).toBe("light");

    // Simulate system preference change to dark mode.
    matches = true;
    for (const listener of matchMediaListeners) {
      listener({ matches } as MediaQueryListEvent);
    }

    // Assert that user preference overrides system preference change.
    expect(document.documentElement.getAttribute("data-theme")).toBe("light");
  });

  it("changes theme when a radio button is selected", () => {
    // Arrange
    initThemeToggle();

    const lightRadio = document.querySelector(
      'input[name="theme"][value="light"]',
    ) as HTMLInputElement;

    // Act
    lightRadio.checked = true;
    lightRadio.dispatchEvent(new Event("change", { bubbles: true }));

    // Assert
    expect(document.documentElement.getAttribute("data-theme")).toBe("light");
    expect(localStorage.getItem("theme")).toBe("light");
  });

  it("saves user preference to localStorage when theme is changed via radio buttons", () => {
    // Arrange
    initThemeToggle();

    const lightRadio = document.querySelector(
      'input[name="theme"][value="light"]',
    ) as HTMLInputElement;

    // Act
    lightRadio.checked = true;
    lightRadio.dispatchEvent(new Event("change", { bubbles: true }));

    // Assert
    expect(localStorage.getItem("theme")).toBe("light");
  });

  it("sets data-theme attribute appropriately when the theme changes via radio buttons", () => {
    // Arrange
    initThemeToggle();

    // Initial state should be dark (default)
    expect(document.documentElement.getAttribute("data-theme")).toBe("dark");

    // Act - Change to light theme
    const lightRadio = document.querySelector(
      'input[name="theme"][value="light"]',
    ) as HTMLInputElement;
    lightRadio.checked = true;
    lightRadio.dispatchEvent(new Event("change", { bubbles: true }));

    // Assert
    expect(document.documentElement.getAttribute("data-theme")).toBe("light");

    // Act - Change back to dark theme
    const darkRadio = document.querySelector(
      'input[name="theme"][value="dark"]',
    ) as HTMLInputElement;
    darkRadio.checked = true;
    darkRadio.dispatchEvent(new Event("change", { bubbles: true }));

    // Assert
    expect(document.documentElement.getAttribute("data-theme")).toBe("dark");
  });

  it("does not throw errors if localStorage is not available", () => {
    // Arrange
    // Simulate localStorage not being available
    Object.defineProperty(window, "localStorage", {
      value: null,
      writable: true,
    });

    // Act
    initThemeToggle();

    // Assert
    expect(document.documentElement.getAttribute("data-theme")).toBe("dark");
  });

  it("applies theme as early as possible to prevent FOUC", () => {
    // Since we're in a testing environment, we can't measure the real DOM rendering performance.
    // However, we can check that the theme attribute is applied synchronously during initialization.

    // Arrange
    let themeAttributeApplied = false;
    const originalSetAttribute = document.documentElement.setAttribute;

    document.documentElement.setAttribute = function (
      name: string,
      value: string,
    ) {
      if (name === "data-theme") {
        themeAttributeApplied = true;
      }
      return originalSetAttribute.call(this, name, value);
    };

    // Act
    initThemeToggle();

    // Assert
    expect(themeAttributeApplied).toBe(true);

    // Clean up
    document.documentElement.setAttribute = originalSetAttribute;
  });
});
