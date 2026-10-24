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
  vi.spyOn(document.documentElement, "scrollHeight", "get").mockReturnValue(
    2800,
  );
  vi.stubGlobal("innerHeight", 800);
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

it("ignores small reversals and clamps overscroll at both document edges", () => {
  scroll(120);
  expect(header.hasAttribute("data-hidden")).toBe(false);
  scroll(300);
  expect(header.hasAttribute("data-hidden")).toBe(true);
  scroll(296);
  scroll(290);
  expect(header.hasAttribute("data-hidden")).toBe(true);
  scroll(280);
  expect(header.hasAttribute("data-hidden")).toBe(false);
  scroll(2100);
  expect(header.hasAttribute("data-hidden")).toBe(true);
  scroll(2020);
  expect(header.hasAttribute("data-hidden")).toBe(true);
  scroll(-20);
  expect(header.hasAttribute("data-hidden")).toBe(false);
  expect(header.hasAttribute("data-scrolled")).toBe(false);
});

it("reveals focused navigation and preserves access during further scrolling", () => {
  scroll(400);
  const link = header.querySelector("a") as HTMLAnchorElement;
  link.focus();
  expect(header.hasAttribute("data-hidden")).toBe(false);
  scroll(700);
  expect(header.hasAttribute("data-hidden")).toBe(false);
  link.blur();
  scroll(780);
  expect(header.hasAttribute("data-hidden")).toBe(true);
});

it("resets during navigation, reconciles patches, and releases listeners on removal", () => {
  scroll(400);
  window.dispatchEvent(new Event("phx:page-loading-start"));
  scroll(800);
  expect(header.hasAttribute("data-hidden")).toBe(false);
  window.dispatchEvent(new Event("phx:page-loading-stop"));
  scroll(900);
  expect(header.hasAttribute("data-hidden")).toBe(true);
  header.removeAttribute("data-hidden");
  hook.updated?.call(context);
  expect(header.hasAttribute("data-hidden")).toBe(true);
  window.dispatchEvent(new Event("popstate"));
  expect(header.hasAttribute("data-hidden")).toBe(false);
  hook.destroyed?.call(context);
  scroll(1000);
  expect(header.hasAttribute("data-hidden")).toBe(false);
  expect(disconnect).toHaveBeenCalledTimes(1);
});
