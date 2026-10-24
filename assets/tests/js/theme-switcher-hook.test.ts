import { expect, it, vi } from "vitest";

it("reconciles patches without multiplying clicks and releases a removed control", async () => {
  vi.resetModules();
  localStorage.clear();
  vi.stubGlobal("matchMedia", () =>
    Object.assign(new EventTarget(), { matches: true }),
  );
  document.body.innerHTML =
    '<button><svg><path data-part="body"/><path data-part="eye"/><path data-part="mouth"/><g data-part="extra-eye"><path/></g><g data-part="nose"><path/></g></svg></button>';
  const button = document.querySelector("button") as HTMLButtonElement;
  const { default: hook } = await import("../../js/hooks/theme_switcher_hook");
  const { themeController } = await import("../../js/theme-switcher");
  const context = { el: button };
  const write = vi.spyOn(Storage.prototype, "setItem");
  try {
    hook.mounted?.call(context);
    for (let i = 0; i < 10; i++) hook.updated?.call(context);
    button.click();
    expect(write).toHaveBeenCalledTimes(1);
    expect(button.getAttribute("aria-pressed")).toBe("true");
    button.removeAttribute("data-ready");
    hook.updated?.call(context);
    expect(button.hasAttribute("data-ready")).toBe(true);
    hook.destroyed?.call(context);
    button.click();
    expect(write).toHaveBeenCalledTimes(1);
  } finally {
    themeController().destroy();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  }
});
