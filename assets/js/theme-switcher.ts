/**
 * Theme Switcher Module
 *
 * This module initializes and manages the theme toggling functionality.
 * It synchronizes the theme between user preferences stored in localStorage
 * and system preferences, applying the appropriate data-theme attribute to the <html> element.
 */

export function initThemeToggle() {
  const root = document.documentElement;

  const THEME_LIGHT = "light";
  const THEME_DARK = "dark";
  const THEME_SYSTEM = "system";

  const STORAGE_KEY = "theme";

  let storageAvailable = true;
  try {
    const testKey = "__storage_test__";
    localStorage.setItem(testKey, testKey);
    localStorage.removeItem(testKey);
  } catch {
    storageAvailable = false;
  }

  const applyTheme = (theme: string) => {
    if (theme === THEME_SYSTEM) {
      root.removeAttribute("data-theme");
    } else {
      root.setAttribute("data-theme", theme);
    }
  };

  const getUserPreference = (): string | null => {
    return storageAvailable ? localStorage.getItem(STORAGE_KEY) : null;
  };

  const saveUserPreference = (theme: string) => {
    if (storageAvailable) {
      try {
        localStorage.setItem(STORAGE_KEY, theme);
      } catch (e) {
        console.error("Failed to save user preference:", e);
      }
    }
  };

  const getSystemPreference = (): string | null => {
    let preference = null;
    if (window.matchMedia) {
      if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
        preference = THEME_DARK;
      } else if (window.matchMedia("(prefers-color-scheme: light)").matches) {
        preference = THEME_LIGHT;
      }
    }
    return preference;
  };

  const getDefaultTheme = (): string => {
    return root.getAttribute("data-theme") || THEME_DARK;
  };

  const setTheme = () => {
    const userPreference = getUserPreference();
    if (userPreference) {
      if (userPreference === THEME_SYSTEM) {
        const systemTheme = getSystemPreference() || getDefaultTheme();
        applyTheme(systemTheme);
      } else {
        applyTheme(userPreference);
      }
    } else {
      const systemPreference = getSystemPreference();
      if (systemPreference) {
        applyTheme(systemPreference);
      } else {
        const defaultTheme = getDefaultTheme();
        applyTheme(defaultTheme);
      }
    }
  };

  const syncRadioButtons = () => {
    const selectedTheme = getUserPreference() || THEME_SYSTEM;
    const radio = document.querySelector(
      `input[name="theme"][value="${selectedTheme}"]`,
    ) as HTMLInputElement;
    if (radio) {
      radio.checked = true;
    }
  };

  setTheme();
  syncRadioButtons();

  if (
    (!getUserPreference() || getUserPreference() === THEME_SYSTEM) &&
    window.matchMedia
  ) {
    const darkThemeMediaQuery = window.matchMedia(
      "(prefers-color-scheme: dark)",
    );

    const systemThemeChangeListener = (e: MediaQueryListEvent) => {
      if (!getUserPreference() || getUserPreference() === THEME_SYSTEM) {
        const newTheme = e.matches ? THEME_DARK : THEME_LIGHT;
        applyTheme(newTheme);
      }
    };

    if (darkThemeMediaQuery.addEventListener) {
      darkThemeMediaQuery.addEventListener("change", systemThemeChangeListener);
    } else if (darkThemeMediaQuery.addListener) {
      darkThemeMediaQuery.addListener(systemThemeChangeListener);
    }
  }

  const themeSwitcherForm = document.getElementById(
    "theme-switcher-form",
  ) as HTMLFormElement;

  if (themeSwitcherForm) {
    themeSwitcherForm.addEventListener("change", (event) => {
      const target = event.target as HTMLInputElement;
      if (target && target.name === "theme") {
        const selectedTheme = target.value;
        if ([THEME_LIGHT, THEME_DARK, THEME_SYSTEM].includes(selectedTheme)) {
          saveUserPreference(selectedTheme);
          setTheme();
          syncRadioButtons();
        }
      }
    });
  }
}
