import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { createSunMoonMotion, ThemeSpring } from "../../js/sun-moon-motion";

it("settles equally at different frame rates and reverses without a position jump", () => {
  for (const hz of [30, 60, 120]) {
    const spring = new ThemeSpring(0);
    spring.target = 1;
    for (let i = 0; i < hz; i++) spring.advance(1 / hz);
    expect(spring.position).toBe(1);
    expect(spring.active).toBe(false);
  }
  const spring = new ThemeSpring(0);
  spring.target = 1;
  spring.advance(0.08);
  const position = spring.position;
  const velocity = spring.velocity;
  spring.target = 0;
  expect(spring.position).toBe(position);
  expect(spring.velocity).toBe(velocity);
  spring.advance(1);
  expect(spring.position).toBe(0);
});
let reduced: EventTarget & { matches: boolean };
let callbacks: Map<number, FrameRequestCallback>;
let motion: ReturnType<typeof createSunMoonMotion>;
beforeEach(() => {
  reduced = Object.assign(new EventTarget(), { matches: false });
  vi.stubGlobal("matchMedia", () => reduced);
  callbacks = new Map();
  let id = 0;
  vi.stubGlobal("requestAnimationFrame", (cb: FrameRequestCallback) => {
    callbacks.set(++id, cb);
    return id;
  });
  vi.stubGlobal("cancelAnimationFrame", (id: number) => callbacks.delete(id));
  document.body.innerHTML =
    '<button><svg><path data-part="body"/><path data-part="eye"/><path data-part="mouth"/><g data-part="extra-eye"><path/></g><g data-part="nose"><path/></g></svg></button>';
  motion = createSunMoonMotion(
    document.querySelector("button") as HTMLButtonElement,
  );
});
afterEach(() => {
  motion?.destroy();
  vi.unstubAllGlobals();
});
it("schedules one frame chain despite rapid toggles and cancels on destruction", () => {
  motion.set(false, false);
  motion.set(true, true);
  motion.set(false, true);
  motion.set(true, true);
  expect(callbacks.size).toBe(1);
  motion.destroy();
  expect(callbacks.size).toBe(0);
});
it("snaps to the endpoint if reduced motion is enabled mid-transition", () => {
  motion.set(true, false);
  const endpoint = document
    .querySelector('[data-part="body"]')
    ?.getAttribute("d");
  motion.set(false, false);
  motion.set(true, true);
  reduced.matches = true;
  reduced.dispatchEvent(new Event("change"));
  expect(callbacks.size).toBe(0);
  expect(document.querySelector('[data-part="body"]')?.getAttribute("d")).toBe(
    endpoint,
  );
});
