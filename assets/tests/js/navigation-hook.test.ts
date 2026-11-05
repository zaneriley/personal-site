import { afterEach, beforeEach, expect, it, vi } from "vitest";
import hook from "../../js/hooks/navigation_hook";

let header: HTMLElement;
let context: { el: HTMLElement };
const disconnect = vi.fn();

function scroll(y: number) {
  vi.stubGlobal("scrollY", y);
  window.dispatchEvent(new Event("scroll"));
}

beforeEach(() => {
  document.body.innerHTML = '<header><a href="/self">Self</a></header>';
  document.body.style.paddingTop = "56px";
  header = document.querySelector("header") as HTMLElement;
  Object.defineProperty(header, "offsetHeight", {
    value: 100,
    configurable: true,
  });
  vi.stubGlobal("scrollY", 0);
  vi.stubGlobal(
    "ResizeObserver",
    class {
      observe() {}
      disconnect = disconnect;
    },
  );
  context = { el: header };
  hook.mounted?.call(context);
});

afterEach(() => {
  hook.destroyed?.call(context);
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
  disconnect.mockClear();
  document.body.removeAttribute("style");
});

it("stays shown and marks scrolled only past the header and body inset", () => {
  scroll(156);
  expect(header.hasAttribute("data-scrolled")).toBe(false);
  scroll(157);
  expect(header.hasAttribute("data-scrolled")).toBe(true);
  scroll(2000);
  expect(header.hasAttribute("data-scrolled")).toBe(true);
  expect(header.hasAttribute("data-hidden")).toBe(false);
  scroll(-20);
  expect(header.hasAttribute("data-scrolled")).toBe(false);
});

it("reconciles patches and releases listeners on removal", () => {
  scroll(400);
  header.removeAttribute("data-scrolled");
  hook.updated?.call(context);
  expect(header.hasAttribute("data-scrolled")).toBe(true);
  hook.destroyed?.call(context);
  expect(header.hasAttribute("data-scrolled")).toBe(false);
  scroll(1000);
  expect(header.hasAttribute("data-scrolled")).toBe(false);
  expect(disconnect).toHaveBeenCalledTimes(1);
});
