/**
 * Cloud Surface Module
 *
 * Animated fbm cloud shader for the light-mode surface, adapted from
 * cloud-prototype/index.html (the "Original" style; the experimental Cumulus
 * variant was dropped — recognizable cloud shapes distract behind body text).
 *
 * The canvas is one layer inside the static `.surface` stack in the root
 * layout, so this module initializes once from app.js — no LiveView hook.
 * Lifecycle is deliberately conservative:
 *   - renders only while light mode is active (mirrors the data-theme /
 *     prefers-color-scheme decision logic in theme-switcher.ts), so dark-mode
 *     users pay zero GPU;
 *   - under prefers-reduced-motion it draws a single static frame instead of
     running the animation loop;
 *   - renders at devicePixelRatio 1 — the clouds are low-frequency, so higher
 *     DPR is imperceptible but costs real battery on a full-viewport canvas.
 * Without WebGL it does nothing and the static gradient + turbulence layers
 * remain as the surface.
 */

const vsSrc = `
attribute vec2 p;
void main() { gl_Position = vec4(p, 0.0, 1.0); }
`;

// Fragment shader: value-noise fbm with the two lowest octaves damped so the
// drift can never white out the screen (worst case ~48% hazy coverage — see
// the prototype's comments). The +25 trajectory offset opens on a pleasant
// stretch of the field, so u_time = 0 is also a good static frame.
const fsSrc = `
precision highp float;

uniform vec2  u_res;
uniform float u_time;

float hash(vec2 p) {
  p = fract(p * vec2(234.34, 435.345));
  p += dot(p, p + 34.23);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float amp = 0.5;
  mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
  for (int i = 0; i < 6; i++) {
    v += amp * noise(p);
    p = rot * p * 2.02 + vec2(13.7, 9.2);
    amp *= 0.5;
  }
  return v;
}

// standard fbm normalized to mean level (amp sum 0.984375)
float fbmN(vec2 p) { return fbm(p) * 1.0159; }

// Original-spectrum fbm with octaves 0-1 damped to bound coverage.
// Amplitudes sum to 1.0.
float fbmSoft(vec2 p) {
  mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
  float v = 0.37915 * noise(p); p = rot * p * 2.02 + vec2(13.7, 9.2);
  v += 0.26540 * noise(p);      p = rot * p * 2.02 + vec2(13.7, 9.2);
  v += 0.18957 * noise(p);      p = rot * p * 2.02 + vec2(13.7, 9.2);
  v += 0.09479 * noise(p);      p = rot * p * 2.02 + vec2(13.7, 9.2);
  v += 0.04739 * noise(p);      p = rot * p * 2.02 + vec2(13.7, 9.2);
  v += 0.02370 * noise(p);
  return v;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_res;
  // aspect-corrected coordinates so clouds don't stretch
  vec2 st = uv;
  st.x *= u_res.x / u_res.y;

  float t = u_time * 0.012;  // slow drift

  // --- sky: very light blue gradient, subtle enough to sit behind content ---
  vec3 skyTop    = vec3(0.825, 0.880, 0.945); // #d2e0f1
  vec3 skyBottom = vec3(0.950, 0.965, 0.982); // #f2f6fa
  vec3 col = mix(skyBottom, skyTop, pow(uv.y, 0.9));

  vec2 p1 = st * 1.6 + vec2(t + 25.0, t * 0.10 + 0.8);
  vec2 warp = vec2(fbmSoft(p1 + vec2(5.2, 1.3)),
                   fbmSoft(p1 + vec2(8.3, 2.8)));
  float c1 = fbmSoft(p1 + warp * 0.7);

  vec2 p2 = st * 3.1 + vec2(t * 1.7 + 53.6, -t * 0.25 - 2.0);
  float c2 = fbmN(p2 + vec2(2.7, 6.1));

  float clouds = c1 * 0.75 + c2 * 0.25;

  float cover = smoothstep(0.492, 0.652, clouds);
  cover = cover * cover * (3.0 - 2.0 * cover);
  cover *= mix(0.5, 1.0, smoothstep(0.0, 0.45, uv.y));

  // flat soft shading: edges tinted barely darker than sky, cores at the
  // site's white point (oklch ~97% L, faintly blue — its lightest authored
  // tone), NOT full white, which reads as blown-out against the palette.
  // Max opacity is deliberately low: the clouds are a veil, not the subject.
  float core = smoothstep(0.545, 0.635, clouds);
  vec3 cloudCol = mix(vec3(0.820, 0.870, 0.930), vec3(0.955, 0.968, 0.988), core);

  col = mix(col, cloudCol, cover * 0.55);

  // faint warm glow, upper left — kept below the white point as well
  float sun = exp(-distance(uv, vec2(0.28, 0.85)) * 3.0) * 0.05;
  col += vec3(0.97, 0.94, 0.89) * sun;

  // soft vignette
  float vig = smoothstep(1.3, 0.4, distance(uv, vec2(0.5)));
  col = mix(col * 0.99, col, vig);

  gl_FragColor = vec4(col, 1.0);
}
`;

function compile(
  gl: WebGLRenderingContext,
  type: number,
  src: string,
): WebGLShader | null {
  const shader = gl.createShader(type);
  if (!shader) return null;
  gl.shaderSource(shader, src);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    console.error("cloud-surface shader:", gl.getShaderInfoLog(shader));
    return null;
  }
  return shader;
}

export function initCloudSurface() {
  // The pre-paint inline script arms the cloud surface (hiding the static
  // light layers from first paint); any failure here must disarm so the
  // fallback layers come back.
  function disarm() {
    document.documentElement.classList.remove("clouds-armed");
  }

  const canvas = document.querySelector<HTMLCanvasElement>(
    "canvas.surface-clouds",
  );
  if (!canvas) {
    disarm();
    return;
  }

  // alpha:false — the canvas is fully opaque; it covers the surface layers
  // beneath it in light mode rather than blending with them.
  const gl = canvas.getContext("webgl", { antialias: false, alpha: false });
  if (!gl) {
    disarm();
    return;
  }

  const vs = compile(gl, gl.VERTEX_SHADER, vsSrc);
  const fs = compile(gl, gl.FRAGMENT_SHADER, fsSrc);
  if (!vs || !fs) {
    disarm();
    return;
  }

  const prog = gl.createProgram();
  if (!prog) {
    disarm();
    return;
  }
  gl.attachShader(prog, vs);
  gl.attachShader(prog, fs);
  gl.linkProgram(prog);
  if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
    console.error("cloud-surface link:", gl.getProgramInfoLog(prog));
    disarm();
    return;
  }
  gl.useProgram(prog);

  const buf = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buf);
  gl.bufferData(
    gl.ARRAY_BUFFER,
    new Float32Array([-1, -1, 3, -1, -1, 3]),
    gl.STATIC_DRAW,
  );
  const loc = gl.getAttribLocation(prog, "p");
  gl.enableVertexAttribArray(loc);
  gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);

  const uRes = gl.getUniformLocation(prog, "u_res");
  const uTime = gl.getUniformLocation(prog, "u_time");

  function resize() {
    if (!gl) return;
    // Size the buffer from the canvas's laid-out size, not window.innerWidth:
    // the two diverge when a scrollbar appears after load, which leaves an
    // unpainted strip the old window-based sizing never repainted.
    const w = Math.max(1, Math.round(canvas.clientWidth));
    const h = Math.max(1, Math.round(canvas.clientHeight));
    if (w === canvas.width && h === canvas.height) return;
    canvas.width = w;
    canvas.height = h;
    gl.viewport(0, 0, w, h);
    // The drawing buffer is cleared by resize; repaint immediately or the
    // canvas flashes black in light mode.
    if (rafId === null && isLight()) draw();
  }

  // Scene time accumulates from real elapsed time (clamped against tab-switch
  // gaps), so pauses and resumes never jump the cloud field.
  let simTime = 0;
  let last = 0;
  let rafId: number | null = null;

  function draw() {
    if (!gl) return;
    gl.uniform2f(uRes, canvas.width, canvas.height);
    gl.uniform1f(uTime, simTime);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    // Reveal only after a real frame is on screen — the opaque context is
    // black until the first draw, and CSS keeps the canvas hidden pre-ready.
    canvas.classList.add("ready");
  }

  function frame(now: number) {
    const dt = Math.min((now - last) / 1000, 0.1);
    last = now;
    simTime += dt;
    draw();
    rafId = requestAnimationFrame(frame);
  }

  function start() {
    if (rafId !== null) return;
    last = performance.now();
    rafId = requestAnimationFrame(frame);
  }

  function stop() {
    if (rafId === null) return;
    cancelAnimationFrame(rafId);
    rafId = null;
  }

  const lightQuery = window.matchMedia("(prefers-color-scheme: light)");
  const motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");

  // Same theme resolution as theme-switcher.ts: explicit data-theme wins,
  // otherwise the OS preference decides.
  function isLight(): boolean {
    const theme = document.documentElement.getAttribute("data-theme");
    return theme ? theme === "light" : lightQuery.matches;
  }

  function sync() {
    if (!isLight()) {
      stop();
      return;
    }
    if (motionQuery.matches) {
      // Reduced motion: one static frame (u_time = 0 is a tuned-pleasant
      // moment of the field), no animation loop.
      stop();
      draw();
    } else {
      start();
    }
  }

  // ResizeObserver catches every cause of a size change — viewport resize,
  // scrollbar appearing as content loads, pinch zoom — where a window resize
  // listener only catches the first. Fall back to it where unavailable.
  if (typeof ResizeObserver !== "undefined") {
    new ResizeObserver(resize).observe(canvas);
  } else {
    window.addEventListener("resize", resize);
  }

  new MutationObserver(sync).observe(document.documentElement, {
    attributes: true,
    attributeFilter: ["data-theme"],
  });
  lightQuery.addEventListener("change", sync);
  motionQuery.addEventListener("change", sync);

  resize();
  sync();
}
