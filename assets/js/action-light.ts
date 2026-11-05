/**
 * Positions the `.action` press light (assets/css/_action.css).
 *
 * One delegated listener for the whole page. A press records where it landed
 * and how far the wave must reach to cover the far rim, then restarts the
 * `is-pressed` animation. Keyboard activation (click with detail 0) presses
 * from the centre. With a mouse, hovering moves the faint light with the cursor.
 */

// How far past the farthest rim point the wave reaches. Lower than the
// composer's 1.8 so the light's hue ramp lands on the rim instead of past it.
const REACH = 1.15;

function place(el: HTMLElement, clientX: number, clientY: number): DOMRect {
  const rect = el.getBoundingClientRect();
  el.style.setProperty("--action-x", `${clientX - rect.left}px`);
  el.style.setProperty("--action-y", `${clientY - rect.top}px`);
  return rect;
}

function press(el: HTMLElement, clientX: number, clientY: number): void {
  const wave = el.querySelector<HTMLElement>(".action-light-wave");
  if (!wave) return;

  const rect = place(el, clientX, clientY);
  const x = clientX - rect.left;
  const y = clientY - rect.top;
  const far = Math.hypot(
    Math.max(x, rect.width - x),
    Math.max(y, rect.height - y),
  );
  el.style.setProperty(
    "--action-scale",
    String((far * 2 * REACH) / wave.offsetWidth),
  );

  el.classList.remove("is-pressed");
  void el.offsetWidth; // restart the animation
  el.classList.add("is-pressed");
}

function actionFrom(target: EventTarget | null): HTMLElement | null {
  return target instanceof Element
    ? target.closest<HTMLElement>(".action")
    : null;
}

export function initActionLight(): void {
  document.addEventListener("pointerdown", (event) => {
    const el = actionFrom(event.target);
    if (el) press(el, event.clientX, event.clientY);
  });

  document.addEventListener("click", (event) => {
    if (event.detail !== 0) return;
    const el = actionFrom(event.target);
    if (!el) return;
    const rect = el.getBoundingClientRect();
    press(el, rect.left + rect.width / 2, rect.top + rect.height / 2);
  });

  document.addEventListener("pointermove", (event) => {
    if (event.pointerType !== "mouse") return;
    const el = actionFrom(event.target);
    if (el && !el.classList.contains("is-pressed"))
      place(el, event.clientX, event.clientY);
  });

  document.addEventListener("animationend", (event) => {
    if (event.animationName !== "action-light-fade") return;
    actionFrom(event.target)?.classList.remove("is-pressed");
  });
}
