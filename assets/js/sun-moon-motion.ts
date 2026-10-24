import paths from "./sun-moon-paths.json";

// Prototype's original artwork, baked at build time; no runtime geometry library.
const smooth = (value: number) => {
  const t = Math.max(0, Math.min(1, value));
  return t * t * (3 - 2 * t);
};
const path = (values: number[]) =>
  `M${values[0]} ${values[1]}C${values.slice(2).join(" ")}Z`;
const interpolate = (pair: number[][], p: number) =>
  path(
    pair[0].map((v, i) => Math.round((v + (pair[1][i] - v) * p) * 1000) / 1000),
  );

/** Exact critically damped spring; retargeting preserves position and velocity. */
export class ThemeSpring {
  position: number;
  target: number;
  velocity = 0;
  constructor(position: number) {
    this.position = this.target = position;
  }
  get active() {
    return this.position !== this.target || this.velocity !== 0;
  }
  settle() {
    this.position = this.target;
    this.velocity = 0;
  }
  advance(seconds: number) {
    if (!this.active || seconds <= 0) return;
    const omega = 9.3 / 0.29; // Prototype's ~290ms settling; no bounce.
    const displacement = this.position - this.target;
    const coefficient = this.velocity + omega * displacement;
    const decay = Math.exp(-omega * seconds);
    this.position =
      this.target + (displacement + coefficient * seconds) * decay;
    this.velocity = (this.velocity - omega * coefficient * seconds) * decay;
    if (
      Math.abs(this.position - this.target) < 0.001 &&
      Math.abs(this.velocity) < 0.03
    )
      this.settle();
  }
}

export function createSunMoonMotion(button: HTMLElement) {
  function required(selector: string) {
    const node = button.querySelector(selector);
    if (!node) throw new Error(`Theme artwork missing ${selector}`);
    return node;
  }
  const body = required('[data-part="body"]');
  const eye = required('[data-part="eye"]');
  const mouth = required('[data-part="mouth"]');
  const extraEye = required('[data-part="extra-eye"]');
  const nose = required('[data-part="nose"]');
  required('[data-part="extra-eye"] path').setAttribute(
    "d",
    path(paths.extraEye),
  );
  required('[data-part="nose"] path').setAttribute("d", path(paths.nose));
  const reduced = matchMedia("(prefers-reduced-motion: reduce)");
  const spring = new ThemeSpring(0);
  let frame = 0;
  let last = 0;
  function draw() {
    const p = Math.max(0, Math.min(1, spring.position));
    body.setAttribute("d", interpolate(paths.body, p));
    eye.setAttribute("d", interpolate(paths.eye, p));
    mouth.setAttribute("d", interpolate(paths.mouth, p));
    extraEye.setAttribute(
      "transform",
      `translate(15.35 10.25) scale(1 ${1 - smooth((p - 0.04) / 0.3)}) translate(-15.35 -10.25)`,
    );
    nose.setAttribute("opacity", String(1 - smooth((p - 0.18) / 0.25)));
  }
  function tick(now: number) {
    frame = 0;
    spring.advance((now - last) / 1000);
    last = now;
    draw();
    if (spring.active) frame = requestAnimationFrame(tick);
  }
  function finish() {
    cancelAnimationFrame(frame);
    frame = 0;
    spring.settle();
    draw();
  }
  const onReduced = () => {
    if (reduced.matches) finish();
  };
  const onVisibility = () => {
    if (document.hidden) finish();
  };
  reduced.addEventListener("change", onReduced);
  document.addEventListener("visibilitychange", onVisibility);
  return {
    set(dark: boolean, animate: boolean) {
      const now = performance.now();
      if (frame) spring.advance((now - last) / 1000);
      last = now;
      spring.target = dark ? 1 : 0;
      if (!animate || reduced.matches || document.hidden) finish();
      else if (!frame && spring.active) frame = requestAnimationFrame(tick);
    },
    destroy() {
      cancelAnimationFrame(frame);
      reduced.removeEventListener("change", onReduced);
      document.removeEventListener("visibilitychange", onVisibility);
    },
  };
}
