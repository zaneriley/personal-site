import { beforeEach, describe, expect, it } from "vitest";
import { initCloudSurface } from "../../js/cloud-surface.ts";

// jsdom has no WebGL — getContext("webgl") returns null — so these tests cover
// the module's contract of degrading to the static surface layers: never throw,
// never reveal the canvas without a rendered frame, and always disarm (restore
// the static layers the pre-paint inline script hid) when init fails.
describe("Cloud Surface Module", () => {
  beforeEach(() => {
    document.documentElement.removeAttribute("data-theme");
    document.documentElement.classList.add("clouds-armed");
    document.body.innerHTML = "";
  });

  it("disarms when the surface canvas is absent", () => {
    expect(() => initCloudSurface()).not.toThrow();
    expect(document.documentElement.classList.contains("clouds-armed")).toBe(
      false,
    );
  });

  it("disarms and leaves the canvas unrevealed when WebGL is unavailable", () => {
    document.body.innerHTML = `<canvas class="surface-layer surface-clouds"></canvas>`;
    document.documentElement.setAttribute("data-theme", "light");

    expect(() => initCloudSurface()).not.toThrow();
    expect(
      document.querySelector(".surface-clouds")?.classList.contains("ready"),
    ).toBe(false);
    expect(document.documentElement.classList.contains("clouds-armed")).toBe(
      false,
    );
  });
});
