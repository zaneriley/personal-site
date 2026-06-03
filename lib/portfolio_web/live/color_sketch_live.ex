defmodule PortfolioWeb.ColorSketchLive do
  @moduledoc false

  use Phoenix.LiveView, layout: false

  @control_specs %{
    bg_a_l: %{default: 100.0, min: 0, max: 100, step: "0.1", label: "Lightness"},
    bg_a_c: %{default: 0.07, min: 0, max: 0.4, step: "0.001", label: "Color"},
    bg_a_h: %{default: 247.0, min: 0, max: 360, step: "0.1", label: "Hue"},
    bg_b_l: %{default: 84.0, min: 0, max: 100, step: "0.1", label: "Lightness"},
    bg_b_c: %{default: 0.141, min: 0, max: 0.4, step: "0.001", label: "Color"},
    bg_b_h: %{default: 238.0, min: 0, max: 360, step: "0.1", label: "Hue"},
    highlight_shape_l: %{
      default: 100.0,
      min: 0,
      max: 100,
      step: "0.1",
      label: "Lightness"
    },
    highlight_shape_c: %{
      default: 0.172,
      min: 0,
      max: 0.4,
      step: "0.001",
      label: "Color"
    },
    highlight_shape_h: %{
      default: 268.8,
      min: 0,
      max: 360,
      step: "0.1",
      label: "Hue"
    },
    shadow_shape_l: %{
      default: 78.9,
      min: 0,
      max: 100,
      step: "0.1",
      label: "Lightness"
    },
    shadow_shape_c: %{
      default: 0.104,
      min: 0,
      max: 0.4,
      step: "0.001",
      label: "Color"
    },
    shadow_shape_h: %{
      default: 360.0,
      min: 0,
      max: 360,
      step: "0.1",
      label: "Hue"
    },
    header_text_l: %{
      default: 32.8,
      min: 0,
      max: 100,
      step: "0.1",
      label: "Lightness"
    },
    header_text_c: %{
      default: 0.056,
      min: 0,
      max: 0.4,
      step: "0.001",
      label: "Color"
    },
    header_text_h: %{default: 48.0, min: 0, max: 360, step: "0.1", label: "Hue"},
    body_text_l: %{
      default: 40.6,
      min: 0,
      max: 100,
      step: "0.1",
      label: "Lightness"
    },
    body_text_c: %{
      default: 0.039,
      min: 0,
      max: 0.4,
      step: "0.001",
      label: "Color"
    },
    body_text_h: %{default: 54.0, min: 0, max: 360, step: "0.1", label: "Hue"},
    link_text_l: %{
      default: 58.7,
      min: 0,
      max: 100,
      step: "0.1",
      label: "Lightness"
    },
    link_text_c: %{
      default: 0.146,
      min: 0,
      max: 0.4,
      step: "0.001",
      label: "Color"
    },
    link_text_h: %{default: 252.0, min: 0, max: 360, step: "0.1", label: "Hue"},
    gradient_type: %{
      default: "radial",
      label: "Gradient",
      kind: :choice,
      options: ~w(linear radial)
    },
    gradient_angle: %{
      default: 10,
      min: 0,
      max: 360,
      step: "1",
      label: "Angle",
      kind: :integer
    },
    gradient_midpoint: %{
      default: 53,
      min: 0,
      max: 100,
      step: "1",
      label: "Midpoint",
      kind: :integer
    },
    gradient_origin_x: %{
      default: 71,
      min: 0,
      max: 100,
      step: "1",
      label: "Origin X",
      kind: :integer
    },
    gradient_origin_y: %{
      default: 26,
      min: 0,
      max: 100,
      step: "1",
      label: "Origin Y",
      kind: :integer
    },
    gradient_size: %{
      default: 123,
      min: 20,
      max: 180,
      step: "1",
      label: "Size",
      kind: :integer
    },
    highlight_size: %{
      default: 109,
      min: 14,
      max: 140,
      step: "1",
      label: "Scale",
      kind: :integer
    },
    highlight_detail: %{
      default: 5,
      min: 1,
      max: 8,
      step: "1",
      label: "Detail",
      kind: :integer
    },
    highlight_variation: %{
      default: 7,
      min: 1,
      max: 99,
      step: "1",
      label: "Variation",
      kind: :integer
    },
    highlight_strength: %{
      default: 0.8,
      min: 0,
      max: 0.8,
      step: "0.01",
      label: "Strength"
    },
    highlight_blend_mode: %{
      default: "normal",
      label: "Blend Mode",
      kind: :choice,
      options: ~w(soft-light overlay multiply screen normal)
    },
    highlight_density: %{
      default: 1.03,
      min: 0.1,
      max: 1.4,
      step: "0.01",
      label: "Contrast"
    },
    highlight_softness: %{
      default: 10,
      min: 0,
      max: 48,
      step: "1",
      label: "Softness",
      kind: :integer
    },
    shadow_size: %{
      default: 14,
      min: 14,
      max: 160,
      step: "1",
      label: "Scale",
      kind: :integer
    },
    shadow_octaves: %{
      default: 3,
      min: 1,
      max: 8,
      step: "1",
      label: "Detail",
      kind: :integer
    },
    shadow_seed: %{
      default: 31,
      min: 1,
      max: 99,
      step: "1",
      label: "Variation",
      kind: :integer
    },
    shadow_opacity: %{
      default: 0.22,
      min: 0,
      max: 0.7,
      step: "0.01",
      label: "Strength"
    },
    shadow_blend_mode: %{
      default: "multiply",
      label: "Blend Mode",
      kind: :choice,
      options: ~w(multiply soft-light overlay screen normal)
    },
    shadow_contrast: %{
      default: 0.1,
      min: 0.1,
      max: 1.6,
      step: "0.01",
      label: "Contrast"
    },
    shadow_blur: %{
      default: 16,
      min: 0,
      max: 56,
      step: "1",
      label: "Softness",
      kind: :integer
    },
    texture_size: %{
      default: 2,
      min: 2,
      max: 32,
      step: "1",
      label: "Size",
      kind: :integer
    },
    texture_opacity: %{
      default: 0.2,
      min: 0,
      max: 0.32,
      step: "0.01",
      label: "Strength"
    },
    texture_blend_mode: %{
      default: "soft-light",
      label: "Blend Mode",
      kind: :choice,
      options: ~w(soft-light overlay multiply screen normal)
    },
    texture_contrast: %{
      default: 1.8,
      min: 0.1,
      max: 1.8,
      step: "0.01",
      label: "Contrast"
    },
    texture_seed: %{
      default: 19,
      min: 1,
      max: 99,
      step: "1",
      label: "Variation",
      kind: :integer
    }
  }

  @impl Phoenix.LiveView
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, assign_controls(socket, default_controls())}
  end

  @impl Phoenix.LiveView
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("update", %{"sketch" => params}, socket) do
    controls = merge_controls(socket.assigns.controls, params)

    {:noreply, assign_controls(socket, controls)}
  end

  def handle_event("update", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="color-sketch" style={@page_style} data-color-sketch>
      <style>
        .color-sketch {
          min-height: 100vh;
          overflow: hidden;
          font-family: "GT Flexa", "Noto Sans JP", -apple-system, system-ui, sans-serif;
          font-weight: 350;
        }

        .color-sketch__stage {
          position: relative;
          isolation: isolate;
          min-height: 100vh;
          padding: 2rem;
        }

        .color-sketch__shape {
          position: absolute;
          inset: 0;
          z-index: -1;
          width: 100%;
          height: 100%;
          mix-blend-mode: var(--shape-blend-mode);
          opacity: var(--shape-opacity);
          pointer-events: none;
        }

        .color-sketch__texture {
          position: absolute;
          inset: 0;
          z-index: 10;
          width: 100%;
          height: 100%;
          mix-blend-mode: var(--texture-blend-mode);
          opacity: var(--texture-opacity);
          pointer-events: none;
        }

        .color-sketch__layout {
          display: grid;
          grid-template-columns: minmax(0, 1fr) 24rem;
          gap: 2rem;
          max-width: 80rem;
          margin-inline: auto;
        }

        .color-sketch__sample {
          display: flex;
          min-height: 72vh;
          align-items: center;
        }

        .color-sketch__copy {
          display: grid;
          gap: 1.25rem;
          max-width: 52rem;
        }

        .color-sketch__eyebrow {
          margin: 0 0 0.75rem;
          color: color-mix(in oklch, var(--body-text) 68%, var(--bg-b));
          font-size: 0.78rem;
          letter-spacing: 0.14em;
          line-height: 1.2;
          text-transform: uppercase;
        }

        .color-sketch__title {
          max-width: 12ch;
          margin: 0;
          color: var(--header-text);
          font-family: "Cardinal Fruit", Garamond, "Times New Roman", serif;
          font-size: 4.75rem;
          line-height: 0.9;
        }

        .color-sketch__lead {
          max-width: 38rem;
          margin: 1.75rem 0 0;
          color: var(--body-text);
          font-size: 1.45rem;
          line-height: 1.36;
        }

        .color-sketch__body {
          max-width: 38rem;
          margin: 1rem 0 0;
          color: var(--body-text);
          font-size: 1rem;
          line-height: 1.55;
        }

        .color-sketch__link {
          display: inline-flex;
          min-height: 44px;
          align-items: center;
          margin-top: 1.25rem;
          border-bottom: 1px solid currentcolor;
          color: var(--link-text);
          font-size: 1rem;
          font-weight: 650;
          text-decoration: none;
        }

        .color-sketch__stress-verdicts {
          display: flex;
          flex-wrap: wrap;
          gap: 0.25rem;
          margin-top: 0.55rem;
        }

        .color-sketch__stress-verdict {
          padding: 0.16rem 0.28rem;
          border: 1px solid rgb(0 0 0 / 12%);
          border-radius: 0.2rem;
          background: rgb(255 255 255 / 26%);
          color: var(--body-text);
          font-size: 0.6rem;
          font-weight: 700;
          line-height: 1.15;
        }

        .color-sketch__stress-verdict[data-result="fail"] {
          color: color-mix(in oklch, var(--shadow-shape) 70%, var(--body-text));
        }

        .color-sketch__stress {
          display: grid;
          gap: 0.75rem;
          max-width: 52rem;
          margin-top: 1.25rem;
        }

        .color-sketch__stress-title {
          margin: 0;
          color: var(--body-text);
          font-size: 0.78rem;
          font-weight: 700;
          letter-spacing: 0.12em;
          line-height: 1.2;
          text-transform: uppercase;
        }

        .color-sketch__stress-grid {
          display: grid;
          grid-template-columns: repeat(5, minmax(0, 1fr));
          gap: 0.5rem;
        }

        .color-sketch__stress-tile {
          min-height: 9.5rem;
          padding: 0.65rem;
          border: 1px solid rgb(0 0 0 / 12%);
          border-radius: 0.25rem;
          box-shadow: inset 0 0 0 1px rgb(255 255 255 / 18%);
        }

        .color-sketch__stress-name {
          margin: 0 0 0.65rem;
          color: color-mix(in oklch, var(--body-text) 74%, transparent);
          font-size: 0.68rem;
          font-weight: 700;
          letter-spacing: 0.08em;
          line-height: 1.2;
          text-transform: uppercase;
        }

        .color-sketch__stress-heading {
          display: block;
          color: var(--header-text);
          font-family: "Cardinal Fruit", Garamond, "Times New Roman", serif;
          font-size: 1.35rem;
          line-height: 0.95;
        }

        .color-sketch__stress-body {
          margin: 0.45rem 0 0;
          color: var(--body-text);
          font-size: 0.72rem;
          line-height: 1.32;
        }

        .color-sketch__stress-link {
          display: inline-block;
          margin-top: 0.5rem;
          border-bottom: 1px solid currentcolor;
          color: var(--link-text);
          font-size: 0.72rem;
          font-weight: 700;
          line-height: 1.2;
          text-decoration: none;
        }

        .color-sketch__controls {
          align-self: start;
          max-height: calc(100vh - 4rem);
          overflow: auto;
          padding: 1rem;
          border: 1px solid rgb(0 0 0 / 10%);
          border-radius: 0.25rem;
          background: rgb(255 255 255 / 55%);
          box-shadow: 0 1px 3px rgb(0 0 0 / 12%);
          backdrop-filter: blur(16px);
        }

        .color-sketch__controls-title {
          margin: 0;
          color: var(--header-text);
          font-family: "Cardinal Fruit", Garamond, "Times New Roman", serif;
          font-size: 2rem;
          line-height: 1;
        }

        .color-sketch__controls-note {
          margin: 0.5rem 0 0;
          color: var(--body-text);
          font-size: 0.86rem;
          line-height: 1.35;
        }

        .color-sketch__workflow {
          margin: 0.55rem 0 0;
          color: color-mix(in oklch, var(--body-text) 72%, var(--bg-b));
          font-size: 0.68rem;
          font-weight: 700;
          letter-spacing: 0.08em;
          line-height: 1.35;
          text-transform: uppercase;
        }

        .color-sketch__control-stack {
          display: grid;
          gap: 1rem;
          margin-top: 1rem;
        }

        .color-sketch__field-group {
          padding: 0.75rem;
          border: 1px solid rgb(0 0 0 / 10%);
          border-radius: 0.25rem;
        }

        .color-sketch__legend {
          padding-inline: 0.25rem;
          color: var(--body-text);
          font-size: 0.86rem;
          font-weight: 650;
        }

        .color-sketch__slider {
          display: grid;
          grid-template-columns: 6.25rem minmax(0, 1fr) 4.5rem;
          gap: 0.5rem;
          align-items: center;
          color: var(--body-text);
          font-size: 0.78rem;
        }

        .color-sketch__slider input {
          width: 100%;
          accent-color: var(--link-text);
        }

        .color-sketch__select {
          min-width: 0;
          width: 100%;
          color: var(--body-text);
          border: 1px solid rgb(0 0 0 / 18%);
          border-radius: 0.25rem;
          background: rgb(255 255 255 / 62%);
          font: inherit;
        }

        .color-sketch__number {
          font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
          text-align: right;
        }

        .color-sketch__readout {
          margin: 0.5rem 0 0;
          color: var(--body-text);
          overflow-wrap: anywhere;
          font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
          font-size: 0.68rem;
          line-height: 1.35;
        }

        .color-sketch__section-title {
          margin: 0;
          color: var(--body-text);
          font-size: 0.78rem;
          font-weight: 700;
          letter-spacing: 0.12em;
          line-height: 1.2;
          text-transform: uppercase;
        }

        .color-sketch__verdict {
          display: grid;
          gap: 0.5rem;
          padding: 0.75rem;
          border: 1px solid rgb(0 0 0 / 12%);
          border-radius: 0.25rem;
          background: rgb(255 255 255 / 34%);
        }

        .color-sketch__status-title {
          margin: 0;
          color: var(--header-text);
          font-size: 1rem;
          font-weight: 750;
          line-height: 1.25;
        }

        .color-sketch__status-text {
          margin: 0;
          color: var(--body-text);
          font-size: 0.78rem;
          line-height: 1.35;
        }

        .color-sketch__contrast {
          display: grid;
          gap: 0.75rem;
          margin-top: 1rem;
        }

        .color-sketch__contrast-row {
          display: grid;
          grid-template-columns: minmax(4rem, 0.8fr) repeat(3, minmax(0, 1fr));
          gap: 0.5rem;
          align-items: center;
          color: var(--body-text);
          font-size: 0.72rem;
          line-height: 1.25;
        }

        .color-sketch__contrast-label {
          font-weight: 700;
        }

        .color-sketch__contrast-chip {
          padding: 0.28rem 0.4rem;
          border: 1px solid rgb(0 0 0 / 12%);
          border-radius: 0.25rem;
          background: rgb(255 255 255 / 42%);
        }

        .color-sketch__contrast-note {
          margin: 0;
          color: color-mix(in oklch, var(--body-text) 78%, var(--bg-b));
          font-size: 0.68rem;
          line-height: 1.35;
        }

        .color-sketch__output {
          max-height: 11rem;
          margin: 0.75rem 0 0;
          overflow: auto;
          padding: 0.75rem;
          border-radius: 0.25rem;
          background: rgb(0 0 0 / 82%);
          color: white;
          font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
          font-size: 0.72rem;
          line-height: 1.45;
        }

        .color-sketch__export summary {
          cursor: pointer;
          color: var(--body-text);
          font-size: 0.78rem;
          font-weight: 700;
          letter-spacing: 0.12em;
          line-height: 1.2;
          text-transform: uppercase;
        }

        .color-sketch__details {
          margin-top: 0.25rem;
        }

        .color-sketch__details summary {
          cursor: pointer;
          color: var(--body-text);
          font-size: 0.72rem;
          font-weight: 700;
          line-height: 1.2;
        }

        @media (max-width: 60rem) {
          .color-sketch__stage {
            padding: 1.25rem;
          }

          .color-sketch__layout {
            grid-template-columns: 1fr;
          }

          .color-sketch__sample {
            min-height: auto;
            padding-block: 3rem;
          }

          .color-sketch__title {
            font-size: 3.35rem;
          }

          .color-sketch__controls {
            max-height: none;
          }

          .color-sketch__stress-grid {
            grid-template-columns: 1fr;
          }
        }
      </style>

      <section class="color-sketch__stage">
        <svg
          class="color-sketch__shape"
          style="--shape-opacity: var(--highlight-opacity); --shape-blend-mode: var(--highlight-blend-mode);"
          aria-hidden="true"
          preserveAspectRatio="none"
        >
          <filter id="color-sketch-highlight-shape">
            <feTurbulence
              type="fractalNoise"
              baseFrequency={@highlight_frequency}
              numOctaves={@controls.highlight_detail}
              seed={@controls.highlight_variation}
              result="noise"
            />
            <feGaussianBlur
              stdDeviation={@controls.highlight_softness}
              result="softNoise"
            />
            <feColorMatrix
              in="softNoise"
              type="matrix"
              values={@highlight_alpha_matrix}
              result="highlightAlpha"
            />
            <feFlood flood-color="var(--highlight-shape)" result="highlightTint" />
            <feComposite
              in="highlightTint"
              in2="highlightAlpha"
              operator="in"
              result="highlightLayer"
            />
          </filter>
          <rect
            width="100%"
            height="100%"
            fill="var(--highlight-shape)"
            filter="url(#color-sketch-highlight-shape)"
          />
        </svg>

        <svg
          class="color-sketch__shape"
          style="--shape-opacity: var(--shadow-opacity); --shape-blend-mode: var(--shadow-blend-mode);"
          aria-hidden="true"
          preserveAspectRatio="none"
        >
          <filter id="color-sketch-shadow-shape">
            <feTurbulence
              type="fractalNoise"
              baseFrequency={@shadow_frequency}
              numOctaves={@controls.shadow_octaves}
              seed={@controls.shadow_seed}
              result="shadowNoise"
            />
            <feGaussianBlur
              stdDeviation={@controls.shadow_blur}
              result="shadowSoftNoise"
            />
            <feColorMatrix
              in="shadowSoftNoise"
              type="matrix"
              values={@shadow_alpha_matrix}
              result="shadowAlpha"
            />
            <feFlood flood-color="var(--shadow-shape)" result="shadowTint" />
            <feComposite
              in="shadowTint"
              in2="shadowAlpha"
              operator="in"
              result="shadowLayer"
            />
          </filter>
          <rect
            width="100%"
            height="100%"
            fill="var(--shadow-shape)"
            filter="url(#color-sketch-shadow-shape)"
          />
        </svg>

        <div class="color-sketch__layout">
          <main class="color-sketch__sample">
            <article class="color-sketch__copy">
              <img
                src="/images/big-name-light.svg"
                alt="Zane Riley"
                width="545"
                height="168"
                style="max-width: 100%; height: auto; margin-bottom: 2.5rem;"
              />
              <p class="color-sketch__eyebrow">Light color sketch</p>
              <h1 class="color-sketch__title">
                A quiet cloud layer for the work
              </h1>
              <p class="color-sketch__lead">
                The background should feel blue before it feels decorative. The text has to stay warm
                enough to belong to the writing, while links get a sharper signal without becoming neon.
              </p>
              <p class="color-sketch__body">
                This is only a sketch surface: two background colors, three independent text colors,
                and the actual SVG shape and texture values that make the surface more or less present.
              </p>
              <a href="/en/self" class="color-sketch__link">
                Read the self portrait
              </a>
              <section
                class="color-sketch__stress"
                aria-labelledby="stress-strip-title"
              >
                <h2 id="stress-strip-title" class="color-sketch__stress-title">
                  Readability samples
                </h2>
                <div class="color-sketch__stress-grid">
                  <div
                    :for={sample <- @stress_samples}
                    class="color-sketch__stress-tile"
                    style={sample.style}
                  >
                    <p class="color-sketch__stress-name">{sample.label}</p>
                    <strong class="color-sketch__stress-heading">Header</strong>
                    <p class="color-sketch__stress-body">
                      Body copy should stay calm and readable.
                    </p>
                    <span class="color-sketch__stress-link">Inline link</span>
                    <div class="color-sketch__stress-verdicts">
                      <span
                        :for={verdict <- sample.verdicts}
                        class="color-sketch__stress-verdict"
                        data-result={verdict.result}
                      >
                        {verdict.label} {verdict.short_result}
                      </span>
                    </div>
                  </div>
                </div>
              </section>
            </article>
          </main>

          <aside class="color-sketch__controls">
            <div>
              <h2 class="color-sketch__controls-title">Light palette sketch</h2>
              <p class="color-sketch__controls-note">
                Judge the samples, then tune surface, text color, light and shadow, and grain.
              </p>
              <p class="color-sketch__workflow">
                1 Preview · 2 Stress test · 3 Readability · 4 Adjust · 5 Export
              </p>
            </div>

            <section
              class="color-sketch__verdict"
              aria-labelledby="contrast-check-title"
            >
              <h3 id="contrast-check-title" class="color-sketch__section-title">
                Readability
              </h3>
              <p class="color-sketch__status-title">{@palette_status.summary}</p>
              <p class="color-sketch__status-text">{@palette_status.guidance}</p>
              <p class="color-sketch__status-text">{@palette_status.supporting}</p>
              <details class="color-sketch__details">
                <summary>Contrast details</summary>
                <div
                  :for={check <- @contrast_checks}
                  class="color-sketch__contrast-row"
                >
                  <span class="color-sketch__contrast-label">{check.label}</span>
                  <span class="color-sketch__contrast-chip">
                    WCAG {check.wcag_ratio}:1 · {check.wcag_result}
                  </span>
                  <span class="color-sketch__contrast-chip">
                    APCA Lc {check.apca_lc}
                  </span>
                  <span class="color-sketch__contrast-chip">
                    Worst: {check.sample}
                  </span>
                </div>
              </details>
              <p class="color-sketch__contrast-note">
                WCAG 2.2 is the hard signal. APCA/Lc is guidance while WCAG 3
                contrast remains unsettled.
              </p>
            </section>

            <.form
              id="color-sketch-controls"
              for={%{}}
              as={:sketch}
              phx-change="update"
              class="space-y-5"
            >
              <div class="color-sketch__control-stack">
                <h3 class="color-sketch__section-title">Surface</h3>
                <h4 class="color-sketch__legend">Surface colors</h4>
                <.color_control
                  title="Light field"
                  color_key={:bg_a}
                  controls={@controls}
                  fields={[:bg_a_l, :bg_a_c, :bg_a_h]}
                  readouts={@readouts}
                />
                <.color_control
                  title="Blue field"
                  color_key={:bg_b}
                  controls={@controls}
                  fields={[:bg_b_l, :bg_b_c, :bg_b_h]}
                  readouts={@readouts}
                />
                <h4 class="color-sketch__legend">Surface gradient</h4>
                <div class="color-sketch__control-stack">
                  <.range_input field={:gradient_midpoint} controls={@controls} />
                  <.range_input field={:gradient_origin_x} controls={@controls} />
                  <.range_input field={:gradient_origin_y} controls={@controls} />
                  <.range_input field={:gradient_size} controls={@controls} />
                </div>
              </div>

              <div class="color-sketch__control-stack">
                <h3 class="color-sketch__section-title">Text colors</h3>
                <.color_control
                  title="Header Text"
                  color_key={:header_text}
                  controls={@controls}
                  fields={[:header_text_l, :header_text_c, :header_text_h]}
                  readouts={@readouts}
                />
                <.color_control
                  title="Body Text"
                  color_key={:body_text}
                  controls={@controls}
                  fields={[:body_text_l, :body_text_c, :body_text_h]}
                  readouts={@readouts}
                />
                <.color_control
                  title="Link Text"
                  color_key={:link_text}
                  controls={@controls}
                  fields={[:link_text_l, :link_text_c, :link_text_h]}
                  readouts={@readouts}
                />
              </div>

              <div class="color-sketch__control-stack">
                <h3 class="color-sketch__section-title">Light and shadow</h3>
                <.color_control
                  title="Highlight wash"
                  color_key={:highlight_shape}
                  controls={@controls}
                  fields={[
                    :highlight_shape_l,
                    :highlight_shape_c,
                    :highlight_shape_h
                  ]}
                  readouts={@readouts}
                />
                <div class="color-sketch__control-stack">
                  <.range_input field={:highlight_size} controls={@controls} />
                  <.range_input field={:highlight_detail} controls={@controls} />
                  <.range_input field={:highlight_variation} controls={@controls} />
                  <.range_input field={:highlight_strength} controls={@controls} />
                  <.choice_input field={:highlight_blend_mode} controls={@controls} />
                  <.range_input field={:highlight_density} controls={@controls} />
                  <.range_input field={:highlight_softness} controls={@controls} />
                </div>
                <.color_control
                  title="Shadow wash"
                  color_key={:shadow_shape}
                  controls={@controls}
                  fields={[:shadow_shape_l, :shadow_shape_c, :shadow_shape_h]}
                  readouts={@readouts}
                />
                <div class="color-sketch__control-stack">
                  <.range_input field={:shadow_size} controls={@controls} />
                  <.range_input field={:shadow_octaves} controls={@controls} />
                  <.range_input field={:shadow_seed} controls={@controls} />
                  <.range_input field={:shadow_opacity} controls={@controls} />
                  <.choice_input field={:shadow_blend_mode} controls={@controls} />
                  <.range_input field={:shadow_contrast} controls={@controls} />
                  <.range_input field={:shadow_blur} controls={@controls} />
                </div>
              </div>

              <div class="color-sketch__control-stack">
                <h3 class="color-sketch__section-title">Grain</h3>
                <div class="color-sketch__control-stack">
                  <.range_input field={:texture_size} controls={@controls} />
                  <.range_input field={:texture_opacity} controls={@controls} />
                  <.choice_input field={:texture_blend_mode} controls={@controls} />
                  <.range_input field={:texture_contrast} controls={@controls} />
                  <.range_input field={:texture_seed} controls={@controls} />
                </div>
              </div>
            </.form>

            <details class="color-sketch__export">
              <summary>Export candidate</summary>
              <pre class="color-sketch__output"><code>{@css_readout}</code></pre>
            </details>
          </aside>
        </div>

        <svg
          class="color-sketch__texture"
          aria-hidden="true"
          preserveAspectRatio="none"
        >
          <filter id="color-sketch-texture">
            <feTurbulence
              type="fractalNoise"
              baseFrequency={@texture_frequency}
              numOctaves="1"
              seed={@controls.texture_seed}
              result="textureNoise"
            />
            <feColorMatrix
              in="textureNoise"
              type="matrix"
              values={@texture_alpha_matrix}
              result="textureAlpha"
            />
            <feFlood flood-color="var(--body-text)" result="textureTint" />
            <feComposite
              in="textureTint"
              in2="textureAlpha"
              operator="in"
              result="textureLayer"
            />
          </filter>
          <rect
            width="100%"
            height="100%"
            fill="var(--body-text)"
            filter="url(#color-sketch-texture)"
          />
        </svg>
      </section>
    </div>
    """
  end

  attr :color_key, :atom, required: true
  attr :controls, :map, required: true
  attr :fields, :list, required: true
  attr :readouts, :map, required: true
  attr :title, :string, required: true

  @spec color_control(map()) :: Phoenix.LiveView.Rendered.t()
  def color_control(assigns) do
    assigns =
      assign(assigns, :readout, Map.fetch!(assigns.readouts, assigns.color_key))

    ~H"""
    <fieldset class="color-sketch__field-group">
      <legend class="color-sketch__legend">
        {@title}
      </legend>
      <div class="color-sketch__control-stack">
        <.range_input :for={field <- @fields} field={field} controls={@controls} />
      </div>
      <p class="color-sketch__readout">
        {@readout}
      </p>
    </fieldset>
    """
  end

  attr :controls, :map, required: true
  attr :field, :atom, required: true

  @spec range_input(map()) :: Phoenix.LiveView.Rendered.t()
  def range_input(assigns) do
    spec = Map.fetch!(@control_specs, assigns.field)

    assigns =
      assigns
      |> assign(:field_name, Atom.to_string(assigns.field))
      |> assign(:label, spec.label)
      |> assign(:max, spec.max)
      |> assign(:min, spec.min)
      |> assign(:step, spec.step)
      |> assign(:value, Map.fetch!(assigns.controls, assigns.field))

    ~H"""
    <label class="color-sketch__slider">
      <span>{@label}</span>
      <input
        id={@field_name}
        name={"sketch[#{@field_name}]"}
        type="range"
        min={@min}
        max={@max}
        step={@step}
        value={@value}
        phx-debounce="80"
      />
      <span class="color-sketch__number">{@value}</span>
    </label>
    """
  end

  attr :controls, :map, required: true
  attr :field, :atom, required: true

  @spec choice_input(map()) :: Phoenix.LiveView.Rendered.t()
  def choice_input(assigns) do
    spec = Map.fetch!(@control_specs, assigns.field)

    assigns =
      assigns
      |> assign(:field_name, Atom.to_string(assigns.field))
      |> assign(:label, spec.label)
      |> assign(:options, spec.options)
      |> assign(:value, Map.fetch!(assigns.controls, assigns.field))

    ~H"""
    <label class="color-sketch__slider">
      <span>{@label}</span>
      <select
        id={@field_name}
        name={"sketch[#{@field_name}]"}
        class="color-sketch__select"
      >
        <option :for={option <- @options} value={option} selected={option == @value}>
          {option}
        </option>
      </select>
      <span class="color-sketch__number">{@value}</span>
    </label>
    """
  end

  defp assign_controls(socket, controls) do
    readouts = build_readouts(controls)
    contrast_checks = build_contrast_checks(controls)

    assign(socket,
      highlight_alpha_matrix: highlight_alpha_matrix(controls),
      highlight_frequency: format_number(highlight_frequency(controls)),
      contrast_checks: contrast_checks,
      controls: controls,
      css_readout: build_css_readout(controls, readouts),
      page_style: build_page_style(controls, readouts),
      palette_status: palette_status(contrast_checks),
      readouts: readouts,
      shadow_alpha_matrix: shadow_alpha_matrix(controls),
      shadow_frequency: format_number(shadow_frequency(controls)),
      stress_samples: build_stress_samples(controls),
      texture_alpha_matrix: texture_alpha_matrix(controls),
      texture_frequency: format_number(texture_frequency(controls))
    )
  end

  defp build_css_readout(controls, readouts) do
    """
    --bg-a: #{readouts.bg_a};
    --bg-b: #{readouts.bg_b};
    --highlight-shape: #{readouts.highlight_shape};
    --shadow-shape: #{readouts.shadow_shape};
    --header-text: #{readouts.header_text};
    --body-text: #{readouts.body_text};
    --link-text: #{readouts.link_text};

    background gradient type="#{controls.gradient_type}"
    background gradient angle="#{controls.gradient_angle}"
    background gradient midpoint="#{controls.gradient_midpoint}"
    background gradient origin="#{controls.gradient_origin_x}% #{controls.gradient_origin_y}%"
    background gradient size="#{controls.gradient_size}"

    highlight feature size="#{controls.highlight_size}"
    highlight feTurbulence baseFrequency="#{format_number(highlight_frequency(controls))}"
                              numOctaves="#{controls.highlight_detail}"
                              seed="#{controls.highlight_variation}"
    highlight blur="#{controls.highlight_softness}"
    highlight opacity="#{format_number(controls.highlight_strength)}"
    highlight blend mode="#{controls.highlight_blend_mode}"
    highlight contrast="#{format_number(controls.highlight_density)}"

    shadow feature size="#{controls.shadow_size}"
    shadow feTurbulence baseFrequency="#{format_number(shadow_frequency(controls))}"
                           numOctaves="#{controls.shadow_octaves}"
                           seed="#{controls.shadow_seed}"
    shadow blur="#{controls.shadow_blur}"
    shadow opacity="#{format_number(controls.shadow_opacity)}"
    shadow blend mode="#{controls.shadow_blend_mode}"
    shadow contrast="#{format_number(controls.shadow_contrast)}"

    surface texture size="#{controls.texture_size}"
    texture feTurbulence baseFrequency="#{format_number(texture_frequency(controls))}"
                         seed="#{controls.texture_seed}"
    texture opacity="#{format_number(controls.texture_opacity)}"
    texture blend mode="#{controls.texture_blend_mode}"
    texture contrast="#{format_number(controls.texture_contrast)}"
    """
  end

  defp build_page_style(controls, readouts) do
    """
    --bg-a: #{readouts.bg_a};
    --bg-b: #{readouts.bg_b};
    --highlight-shape: #{readouts.highlight_shape};
    --shadow-shape: #{readouts.shadow_shape};
    --header-text: #{readouts.header_text};
    --body-text: #{readouts.body_text};
    --link-text: #{readouts.link_text};
    --highlight-opacity: #{format_number(controls.highlight_strength)};
    --highlight-blend-mode: #{controls.highlight_blend_mode};
    --shadow-opacity: #{format_number(controls.shadow_opacity)};
    --shadow-blend-mode: #{controls.shadow_blend_mode};
    --texture-opacity: #{format_number(controls.texture_opacity)};
    --texture-blend-mode: #{controls.texture_blend_mode};
    background: #{background_gradient(controls)};
    """
  end

  defp build_readouts(controls) do
    %{
      bg_a: oklch(controls.bg_a_l, controls.bg_a_c, controls.bg_a_h),
      bg_b: oklch(controls.bg_b_l, controls.bg_b_c, controls.bg_b_h),
      highlight_shape:
        oklch(
          controls.highlight_shape_l,
          controls.highlight_shape_c,
          controls.highlight_shape_h
        ),
      shadow_shape:
        oklch(
          controls.shadow_shape_l,
          controls.shadow_shape_c,
          controls.shadow_shape_h
        ),
      body_text:
        oklch(controls.body_text_l, controls.body_text_c, controls.body_text_h),
      header_text:
        oklch(
          controls.header_text_l,
          controls.header_text_c,
          controls.header_text_h
        ),
      link_text:
        oklch(controls.link_text_l, controls.link_text_c, controls.link_text_h)
    }
  end

  defp build_contrast_checks(controls) do
    samples = background_samples(controls)

    [
      contrast_check(
        "Header",
        oklch_color(controls, :header_text),
        samples,
        :large
      ),
      contrast_check(
        "Body",
        oklch_color(controls, :body_text),
        samples,
        :normal
      ),
      contrast_check(
        "Link",
        oklch_color(controls, :link_text),
        samples,
        :normal
      )
    ]
  end

  defp contrast_check(label, text_color, samples, size) do
    {sample_name, wcag_ratio, apca_lc} =
      samples
      |> Enum.map(fn {sample_name, background_color} ->
        {sample_name, wcag_contrast(text_color, background_color),
         apca_contrast(text_color, background_color)}
      end)
      |> Enum.min_by(fn {_sample_name, wcag_ratio, _apca_lc} -> wcag_ratio end)

    %{
      apca_lc: format_number(abs(apca_lc)),
      label: label,
      result: contrast_result(wcag_ratio, size),
      sample: sample_name,
      wcag_ratio: format_number(wcag_ratio),
      wcag_result: wcag_result(wcag_ratio, size)
    }
  end

  defp palette_status(contrast_checks) do
    failed_checks = Enum.filter(contrast_checks, &(&1.result == "fail"))

    case failed_checks do
      [] ->
        %{
          summary: "Header, body, and links are readable.",
          guidance:
            "The current palette clears the sampled light and shadow surfaces.",
          supporting: "Keep tuning by feel; the hard contrast signal is safe."
        }

      [failed_check | _rest] ->
        %{
          summary: "#{failed_check.label} fails on #{failed_check.sample}.",
          guidance:
            "Try lowering lightness or color strength for #{String.downcase(failed_check.label)}.",
          supporting: safe_checks_summary(contrast_checks)
        }
    end
  end

  defp safe_checks_summary(contrast_checks) do
    safe_labels =
      contrast_checks
      |> Enum.reject(&(&1.result == "fail"))
      |> Enum.map_join(" and ", &String.downcase(&1.label))

    if safe_labels == "" do
      "No text role clears the sampled backgrounds yet."
    else
      "#{String.capitalize(safe_labels)} are safe."
    end
  end

  defp contrast_result(ratio, :large) when ratio >= 3, do: "pass"
  defp contrast_result(ratio, :normal) when ratio >= 4.5, do: "pass"
  defp contrast_result(_ratio, _size), do: "fail"

  defp wcag_result(ratio, :large) when ratio >= 4.5, do: "AAA pass"
  defp wcag_result(ratio, :large) when ratio >= 3, do: "AA pass"
  defp wcag_result(_ratio, :large), do: "fail"
  defp wcag_result(ratio, :normal) when ratio >= 7, do: "AAA pass"
  defp wcag_result(ratio, :normal) when ratio >= 4.5, do: "AA pass"
  defp wcag_result(_ratio, :normal), do: "fail"

  defp background_samples(controls) do
    bg_a = oklch_color(controls, :bg_a)
    bg_b = oklch_color(controls, :bg_b)
    midpoint = mix_oklch(bg_a, bg_b, 0.5)
    highlight = oklch_color(controls, :highlight_shape)
    shadow = oklch_color(controls, :shadow_shape)

    [
      {"light field", bg_a},
      {"blue field", bg_b},
      {"gradient midpoint", midpoint},
      {"highlight wash",
       alpha_blend(highlight, midpoint, controls.highlight_strength)},
      {"shadow wash",
       blended_shape(
         shadow,
         midpoint,
         controls.shadow_opacity,
         controls.shadow_blend_mode
       )}
    ]
  end

  defp build_stress_samples(controls) do
    text_samples = [
      {"Header", oklch_color(controls, :header_text), :large},
      {"Body", oklch_color(controls, :body_text), :normal},
      {"Link", oklch_color(controls, :link_text), :normal}
    ]

    controls
    |> background_samples()
    |> Enum.map(fn {label, color} ->
      %{
        label: label,
        style: "background: #{color_css(color)};",
        verdicts: stress_verdicts(text_samples, color)
      }
    end)
  end

  defp stress_verdicts(text_samples, background_color) do
    Enum.map(text_samples, fn {label, text_color, size} ->
      ratio = wcag_contrast(text_color, background_color)

      %{
        label: label,
        result: contrast_result(ratio, size),
        short_result: short_wcag_result(ratio, size)
      }
    end)
  end

  defp short_wcag_result(ratio, :large) when ratio >= 3, do: "OK"
  defp short_wcag_result(ratio, :normal) when ratio >= 4.5, do: "OK"
  defp short_wcag_result(_ratio, _size), do: "FAIL"

  defp oklch_color(controls, :bg_a),
    do: color_value(controls.bg_a_l, controls.bg_a_c, controls.bg_a_h)

  defp oklch_color(controls, :bg_b),
    do: color_value(controls.bg_b_l, controls.bg_b_c, controls.bg_b_h)

  defp oklch_color(controls, :body_text),
    do:
      color_value(
        controls.body_text_l,
        controls.body_text_c,
        controls.body_text_h
      )

  defp oklch_color(controls, :header_text),
    do:
      color_value(
        controls.header_text_l,
        controls.header_text_c,
        controls.header_text_h
      )

  defp oklch_color(controls, :highlight_shape),
    do:
      color_value(
        controls.highlight_shape_l,
        controls.highlight_shape_c,
        controls.highlight_shape_h
      )

  defp oklch_color(controls, :link_text),
    do:
      color_value(
        controls.link_text_l,
        controls.link_text_c,
        controls.link_text_h
      )

  defp oklch_color(controls, :shadow_shape),
    do:
      color_value(
        controls.shadow_shape_l,
        controls.shadow_shape_c,
        controls.shadow_shape_h
      )

  defp color_value(lightness, chroma, hue) do
    %{
      chroma: chroma,
      hue: hue,
      lightness: lightness / 100
    }
  end

  defp mix_oklch(color_a, color_b, amount_b) do
    amount_a = 1 - amount_b

    %{
      chroma: color_a.chroma * amount_a + color_b.chroma * amount_b,
      hue: mix_hue(color_a.hue, color_b.hue, amount_b),
      lightness: color_a.lightness * amount_a + color_b.lightness * amount_b
    }
  end

  defp mix_hue(hue_a, hue_b, amount_b) do
    delta = rem(round(hue_b - hue_a + 540), 360) - 180
    normalize_hue(hue_a + delta * amount_b)
  end

  defp normalize_hue(hue) when hue < 0, do: normalize_hue(hue + 360)
  defp normalize_hue(hue) when hue > 360, do: normalize_hue(hue - 360)
  defp normalize_hue(hue), do: hue

  defp blended_shape(shape_color, background_color, opacity, "multiply") do
    shape_color
    |> multiply_blend(background_color)
    |> alpha_blend(background_color, opacity)
  end

  defp blended_shape(shape_color, background_color, opacity, _blend_mode) do
    alpha_blend(shape_color, background_color, opacity)
  end

  defp multiply_blend(shape_color, background_color) do
    shape_rgb = oklch_to_srgb(shape_color)
    background_rgb = oklch_to_srgb(background_color)

    %{
      blue: shape_rgb.blue * background_rgb.blue,
      green: shape_rgb.green * background_rgb.green,
      red: shape_rgb.red * background_rgb.red
    }
  end

  defp alpha_blend(foreground_color, background_color, opacity) do
    foreground_rgb = color_to_srgb(foreground_color)
    background_rgb = color_to_srgb(background_color)

    %{
      blue: foreground_rgb.blue * opacity + background_rgb.blue * (1 - opacity),
      green:
        foreground_rgb.green * opacity + background_rgb.green * (1 - opacity),
      red: foreground_rgb.red * opacity + background_rgb.red * (1 - opacity)
    }
  end

  defp color_to_srgb(%{red: _red, green: _green, blue: _blue} = rgb), do: rgb
  defp color_to_srgb(oklch_color), do: oklch_to_srgb(oklch_color)

  defp color_css(%{red: _red, green: _green, blue: _blue} = rgb) do
    red = (rgb.red * 255) |> round()
    green = (rgb.green * 255) |> round()
    blue = (rgb.blue * 255) |> round()

    "rgb(#{red} #{green} #{blue})"
  end

  defp color_css(%{lightness: lightness, chroma: chroma, hue: hue}) do
    "oklch(#{format_percent(lightness * 100)} #{format_number(chroma)} #{format_degrees(hue)})"
  end

  defp wcag_contrast(text_color, background_color) do
    text_luminance = relative_luminance(text_color)
    background_luminance = relative_luminance(background_color)
    lighter = max(text_luminance, background_luminance)
    darker = min(text_luminance, background_luminance)

    (lighter + 0.05) / (darker + 0.05)
  end

  defp relative_luminance(color) do
    rgb = color_to_srgb(color)
    linear_rgb = srgb_to_linear_rgb(rgb)

    0.2126 * linear_rgb.red + 0.7152 * linear_rgb.green +
      0.0722 * linear_rgb.blue
  end

  defp apca_contrast(text_color, background_color) do
    text_luminance = apca_luminance(text_color)
    background_luminance = apca_luminance(background_color)

    cond do
      abs(background_luminance - text_luminance) < 0.0005 ->
        0

      background_luminance > text_luminance ->
        sapc =
          (:math.pow(background_luminance, 0.56) -
             :math.pow(text_luminance, 0.57)) *
            1.14

        if sapc < 0.1, do: 0, else: (sapc - 0.027) * 100

      true ->
        sapc =
          (:math.pow(background_luminance, 0.65) -
             :math.pow(text_luminance, 0.62)) *
            1.14

        if sapc > -0.1, do: 0, else: (sapc + 0.027) * 100
    end
  end

  defp apca_luminance(color) do
    rgb = color_to_srgb(color)

    luminance =
      0.2126729 * :math.pow(rgb.red, 2.4) +
        0.7151522 * :math.pow(rgb.green, 2.4) +
        0.072175 * :math.pow(rgb.blue, 2.4)

    if luminance >= 0.022 do
      luminance
    else
      luminance + :math.pow(0.022 - luminance, 1.414)
    end
  end

  defp oklch_to_srgb(%{chroma: chroma, hue: hue, lightness: lightness}) do
    hue_radians = hue * :math.pi() / 180
    ok_a = chroma * :math.cos(hue_radians)
    ok_b = chroma * :math.sin(hue_radians)

    l_prime = lightness + 0.3963377774 * ok_a + 0.2158037573 * ok_b
    m_prime = lightness - 0.1055613458 * ok_a - 0.0638541728 * ok_b
    s_prime = lightness - 0.0894841775 * ok_a - 1.291485548 * ok_b

    l = l_prime * l_prime * l_prime
    m = m_prime * m_prime * m_prime
    s = s_prime * s_prime * s_prime

    %{
      red:
        linear_to_srgb(
          clamp(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, 0, 1)
        ),
      green:
        linear_to_srgb(
          clamp(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, 0, 1)
        ),
      blue:
        linear_to_srgb(
          clamp(-0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s, 0, 1)
        )
    }
  end

  defp srgb_to_linear_rgb(rgb) do
    %{
      blue: srgb_to_linear(rgb.blue),
      green: srgb_to_linear(rgb.green),
      red: srgb_to_linear(rgb.red)
    }
  end

  defp linear_to_srgb(value) when value <= 0.0031308, do: 12.92 * value
  defp linear_to_srgb(value), do: 1.055 * :math.pow(value, 1 / 2.4) - 0.055

  defp srgb_to_linear(value) when value <= 0.04045, do: value / 12.92
  defp srgb_to_linear(value), do: :math.pow((value + 0.055) / 1.055, 2.4)

  defp default_controls do
    Map.new(@control_specs, fn {field, spec} -> {field, spec.default} end)
  end

  defp merge_controls(controls, params) do
    Enum.reduce(@control_specs, controls, fn {field, spec}, merged_controls ->
      field_name = Atom.to_string(field)
      current_value = Map.fetch!(controls, field)

      value =
        case spec[:kind] do
          :choice ->
            parse_choice(Map.get(params, field_name), current_value, spec)

          :integer ->
            parse_integer(Map.get(params, field_name), current_value, spec)

          _kind ->
            parse_float(Map.get(params, field_name), current_value, spec)
        end

      Map.put(merged_controls, field, value)
    end)
  end

  defp parse_float(nil, current_value, _spec), do: current_value

  defp parse_float(value, current_value, spec) do
    case Float.parse(value) do
      {parsed_value, _rest} -> clamp(parsed_value, spec.min, spec.max)
      :error -> current_value
    end
  end

  defp parse_integer(nil, current_value, _spec), do: current_value

  defp parse_integer(value, current_value, spec) do
    case Integer.parse(value) do
      {parsed_value, _rest} -> clamp(parsed_value, spec.min, spec.max)
      :error -> current_value
    end
  end

  defp parse_choice(nil, current_value, _spec), do: current_value

  defp parse_choice(value, current_value, spec) do
    if value in spec.options do
      value
    else
      current_value
    end
  end

  defp clamp(value, min, _max) when value < min, do: min
  defp clamp(value, _min, max) when value > max, do: max
  defp clamp(value, _min, _max), do: value

  defp highlight_frequency(controls) do
    1 / controls.highlight_size
  end

  defp background_gradient(%{gradient_type: "radial"} = controls) do
    "radial-gradient(circle at #{controls.gradient_origin_x}% #{controls.gradient_origin_y}%, var(--bg-a) 0%, color-mix(in oklch, var(--bg-a) 50%, var(--bg-b)) #{controls.gradient_midpoint}%, var(--bg-b) #{controls.gradient_size}%)"
  end

  defp background_gradient(controls) do
    "linear-gradient(#{controls.gradient_angle}deg, var(--bg-a) 0%, color-mix(in oklch, var(--bg-a) 50%, var(--bg-b)) #{controls.gradient_midpoint}%, var(--bg-b) 100%)"
  end

  defp shadow_frequency(controls) do
    1 / controls.shadow_size
  end

  defp highlight_alpha_matrix(controls) do
    red = format_number(0.2126 * controls.highlight_density)
    green = format_number(0.7152 * controls.highlight_density)
    blue = format_number(0.0722 * controls.highlight_density)

    "0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  #{red} #{green} #{blue} 0 0"
  end

  defp shadow_alpha_matrix(controls) do
    red = format_number(0.2126 * controls.shadow_contrast)
    green = format_number(0.7152 * controls.shadow_contrast)
    blue = format_number(0.0722 * controls.shadow_contrast)

    "0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  #{red} #{green} #{blue} 0 0"
  end

  defp texture_frequency(controls) do
    1 / controls.texture_size
  end

  defp texture_alpha_matrix(controls) do
    red = format_number(0.2126 * controls.texture_contrast)
    green = format_number(0.7152 * controls.texture_contrast)
    blue = format_number(0.0722 * controls.texture_contrast)

    "0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  #{red} #{green} #{blue} 0 0"
  end

  defp oklch(lightness, chroma, hue) do
    "oklch(#{format_percent(lightness)} #{format_number(chroma)} #{format_degrees(hue)})"
  end

  defp format_percent(value), do: "#{format_number(value)}%"
  defp format_degrees(value), do: "#{format_number(value)}deg"

  defp format_number(value) when is_integer(value), do: Integer.to_string(value)

  defp format_number(value) do
    value
    |> :erlang.float_to_binary(decimals: 3)
    |> String.trim_trailing("0")
    |> String.trim_trailing(".")
  end
end
