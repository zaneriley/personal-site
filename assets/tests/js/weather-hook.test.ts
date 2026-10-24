import { afterEach, expect, it, vi } from "vitest";
import hook from "../../js/hooks/weather_hook";

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

it("does no initial work, animates changed digits only, and cancels on hide or reduced motion", () => {
  const preference = Object.assign(new EventTarget(), { matches: false });
  vi.stubGlobal("matchMedia", () => preference);
  let intersection: (entries: { isIntersecting: boolean }[]) => void = () => {
    throw new Error("Observer not installed");
  };
  const disconnect = vi.fn();
  vi.stubGlobal(
    "IntersectionObserver",
    class {
      constructor(callback: typeof intersection) {
        intersection = callback;
      }
      observe() {}
      disconnect = disconnect;
    },
  );
  document.body.innerHTML =
    '<div><span data-place="0" data-digit="4" style="transform:rotate(7deg)">4</span></div>';
  const el = document.body.firstElementChild as HTMLElement;
  const digit = el.firstElementChild as HTMLElement;
  const animation = { cancel: vi.fn(), onfinish: null, oncancel: null };
  digit.animate = vi.fn(() => animation as unknown as Animation);
  const ctx = { el, pushEvent: vi.fn() } as unknown as Parameters<
    typeof hook.mounted.call
  >[0];
  hook.mounted.call(ctx);
  expect(digit.animate).not.toHaveBeenCalled();
  intersection([{ isIntersecting: true }]);
  hook.beforeUpdate.call(ctx);
  hook.updated.call(ctx);
  expect(digit.animate).not.toHaveBeenCalled();
  hook.beforeUpdate.call(ctx);
  digit.dataset.digit = "5";
  hook.updated.call(ctx);
  expect(digit.animate).toHaveBeenCalledTimes(1);
  expect(digit.animate).toHaveBeenCalledWith(expect.any(Array), {
    duration: 240,
    easing: "cubic-bezier(0.2, 0, 0, 1)",
  });
  preference.matches = true;
  preference.dispatchEvent(new Event("change"));
  expect(animation.cancel).toHaveBeenCalledTimes(1);
  hook.beforeUpdate.call(ctx);
  digit.dataset.digit = "6";
  hook.updated.call(ctx);
  expect(digit.animate).toHaveBeenCalledTimes(1);
  preference.matches = false;
  intersection([{ isIntersecting: false }]);
  hook.beforeUpdate.call(ctx);
  digit.dataset.digit = "7";
  hook.updated.call(ctx);
  expect(digit.animate).toHaveBeenCalledTimes(1);
  hook.destroyed.call(ctx);
  expect(disconnect).toHaveBeenCalledOnce();
  document.dispatchEvent(new Event("visibilitychange"));
  expect(ctx.pushEvent).not.toHaveBeenCalled();
});
