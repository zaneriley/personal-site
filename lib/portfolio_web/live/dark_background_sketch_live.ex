defmodule PortfolioWeb.DarkBackgroundSketchLive do
  @moduledoc false
  use Phoenix.LiveView, layout: false
  import PortfolioWeb.Components.Identity

  alias Phoenix.LiveView.Socket

  # Color stops are free-text so Figma hex/oklch can be pasted directly.
  # An empty color string disables that stop.
  @text_fields ~w(
    base
    g1_s1_color g1_s2_color g1_s3_color g1_s4_color g1_s5_color
    g2_s1_color g2_s2_color g2_s3_color g2_s4_color g2_s5_color
  )

  @choice_fields %{
    "g1_type" => ~w(radial linear),
    "g2_type" => ~w(linear radial),
    "g1_blend" =>
      ~w(normal screen multiply overlay soft-light lighten color-dodge),
    "g2_blend" =>
      ~w(normal screen multiply overlay soft-light lighten color-dodge),
    "tex_blend" => ~w(overlay soft-light multiply screen normal)
  }

  # {field, min, max, step}
  @number_fields [
    {"g1_angle", 0, 360, 1},
    {"g1_ox", 0, 100, 1},
    {"g1_oy", 0, 100, 1},
    {"g1_size", 20, 200, 1},
    {"g1_opacity", 0, 1, 0.01},
    {"g1_s1_pos", 0, 100, 1},
    {"g1_s2_pos", 0, 100, 1},
    {"g1_s3_pos", 0, 100, 1},
    {"g1_s4_pos", 0, 100, 1},
    {"g1_s5_pos", 0, 100, 1},
    {"g2_angle", 0, 360, 1},
    {"g2_ox", 0, 100, 1},
    {"g2_oy", 0, 100, 1},
    {"g2_size", 20, 200, 1},
    {"g2_opacity", 0, 1, 0.01},
    {"g2_s1_pos", 0, 100, 1},
    {"g2_s2_pos", 0, 100, 1},
    {"g2_s3_pos", 0, 100, 1},
    {"g2_s4_pos", 0, 100, 1},
    {"g2_s5_pos", 0, 100, 1},
    {"tex_size", 1, 32, 1},
    {"tex_opacity", 0, 0.6, 0.01},
    {"tex_contrast", 0.1, 2, 0.01},
    {"tex_seed", 1, 99, 1}
  ]

  # Seed: the real Figma background ramp (bg-100 -> bg-90 -> bg-80) as one
  # subtle radial curve. Low-chroma cool grays, hue drifting purple -> blue.
  @defaults %{
    "base" => "oklch(25.7% 0.006 286deg)",
    "g1_type" => "radial",
    "g1_angle" => 10,
    "g1_ox" => 75,
    "g1_oy" => 18,
    "g1_size" => 150,
    "g1_blend" => "normal",
    "g1_opacity" => 1.0,
    "g1_s1_color" => "oklch(25.7% 0.006 286deg)",
    "g1_s1_pos" => 0,
    "g1_s2_color" => "oklch(27.5% 0.009 286deg)",
    "g1_s2_pos" => 50,
    "g1_s3_color" => "oklch(33.1% 0.022 259deg)",
    "g1_s3_pos" => 100,
    "g1_s4_color" => "",
    "g1_s4_pos" => 77,
    "g1_s5_color" => "",
    "g1_s5_pos" => 100,
    "g2_type" => "linear",
    "g2_angle" => 200,
    "g2_ox" => 50,
    "g2_oy" => 50,
    "g2_size" => 140,
    "g2_blend" => "screen",
    "g2_opacity" => 0.0,
    "g2_s1_color" => "oklch(53.3% 0.038 277deg)",
    "g2_s1_pos" => 0,
    "g2_s2_color" => "oklch(25.7% 0.006 286deg)",
    "g2_s2_pos" => 100,
    "g2_s3_color" => "",
    "g2_s3_pos" => 50,
    "g2_s4_color" => "",
    "g2_s4_pos" => 75,
    "g2_s5_color" => "",
    "g2_s5_pos" => 100,
    "tex_size" => 2,
    "tex_opacity" => 0.14,
    "tex_blend" => "overlay",
    "tex_contrast" => 1.0,
    "tex_seed" => 36
  }

  # Real token set pulled from Figma, for the on-surface reference board.
  # {label, hex, optical-bright sibling | nil}
  @token_groups [
    {"Background",
     [
       {"bg-100", "#232326", nil},
       {"bg-90", "#27272C", nil},
       {"bg-80", "#2F3641", nil}
     ]},
    {"Neutral / text",
     [
       {"100", "#D9D9D9", nil},
       {"75", "#C7B0C2", nil},
       {"50", "#949CD1", "#7D8BE8"},
       {"25", "#676B83", nil}
     ]},
    {"Coding accents",
     [
       {"green", "#85B695", nil},
       {"yellow", "#EBC06D", nil},
       {"brown", "#867462", nil},
       {"white", "#ECE1D7", nil},
       {"blue", "#88B2B5", nil}
     ]}
  ]

  # WCAG ratios vs the lightest gradient stop (bg-80) — the readability floor.
  # {role, hex, ratio, tag}
  @text_contrast [
    {"Heading", "#ECE1D7", "9.5", "AAA"},
    {"Body", "#D9D9D9", "8.6", "AAA"},
    {"Secondary", "#676B83", "2.3", "FAIL"},
    {"Link", "#949CD1", "4.6", "AA"},
    {"Link hover", "#7D8BE8", "3.9", "AA-lg"}
  ]

  @impl Phoenix.LiveView
  @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, assign_derived(socket, @defaults)}
  end

  @impl Phoenix.LiveView
  @spec handle_event(String.t(), map(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_event("update", %{"sketch" => params}, socket) do
    {:noreply, assign_derived(socket, merge(socket.assigns.controls, params))}
  end

  def handle_event("update", _params, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="dbs" style={@page_style}>
      <style>
        .dbs {
          min-height: 100vh;
          display: grid;
          grid-template-columns: minmax(0, 1fr) 24rem;
          font-family: "GT Flexa", system-ui, sans-serif;
          font-weight: 350;
          color: oklch(88% 0.056 324deg);

          /* Semantic token mapping (fixed real tokens) */
          --t-heading: #ECE1D7;   /* coding white */
          --t-body: #D9D9D9;      /* neutral-100 */
          --t-secondary: #676B83; /* neutral-25 — decorative only, fails body contrast */
          --t-link: #949CD1;      /* neutral-50 */
          --t-link-hover: #7D8BE8; /* neutral-50-bright */
          --a-green: #85B695;
          --a-yellow: #EBC06D;
          --a-brown: #867462;
          --a-blue: #88B2B5;
        }

        @media (max-width: 60rem) {
          .dbs { grid-template-columns: 1fr; }
        }

        .dbs__stage {
          position: relative;
          isolation: isolate;
          min-height: 100vh;
          padding: 3rem;
          background: var(--dbs-bg);
          background-blend-mode: var(--dbs-blend);
          background-color: var(--dbs-base);
        }

        .dbs__texture {
          position: absolute;
          inset: 0;
          z-index: 0;
          width: 100%;
          height: 100%;
          mix-blend-mode: var(--tex-blend);
          opacity: var(--tex-opacity);
          pointer-events: none;
        }

        .dbs__sample {
          position: relative;
          z-index: 1;
          max-width: 34rem;
        }

        .dbs__logo {
          display: block;
          max-width: 100%;
          height: auto;
          margin-bottom: 3rem;
        }

        .dbs__title {
          font-family: "Cardinal Fruit", Garamond, serif;
          font-size: 3.25rem;
          line-height: 0.92;
          margin: 0 0 1.25rem;
          color: oklch(90.76% 0.0184 316.61deg);
        }

        .dbs__body {
          font-size: 1.05rem;
          line-height: 1.5;
          max-width: 32rem;
        }

        .dbs__eyebrow {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          margin: 0 0 0.75rem;
          font-size: 0.7rem;
          font-weight: 700;
          letter-spacing: 0.14em;
          text-transform: uppercase;
          color: var(--t-secondary);
        }

        .dbs__chip {
          font-size: 0.55rem;
          font-weight: 600;
          letter-spacing: 0.03em;
          text-transform: none;
          color: var(--t-secondary);
          border: 1px solid oklch(100% 0 0 / 14%);
          border-radius: 0.2rem;
          padding: 0.05rem 0.3rem;
        }

        .dbs__lead {
          margin: 0 0 1rem;
          max-width: 34rem;
          color: var(--t-body);
          font-size: 1.15rem;
          line-height: 1.5;
        }

        .dbs__meta {
          margin: 0 0 1.5rem;
          color: var(--t-secondary);
          font-size: 0.85rem;
        }

        .dbs__link {
          color: var(--t-link);
          text-decoration: none;
          border-bottom: 1px solid currentcolor;
          transition: color 0.15s;
        }

        .dbs__link:hover { color: var(--t-link-hover); }

        .dbs__inline-hover { color: var(--t-link-hover); font-weight: 500; }

        .dbs__card {
          margin: 0 0 1.5rem;
          max-width: 34rem;
          padding: 1.25rem;
          border-radius: 0.4rem;
          background: #27272C; /* bg-90 */
          border: 1px solid oklch(100% 0 0 / 8%);
        }

        .dbs__card-title {
          margin: 0 0 0.5rem;
          font-family: "Cardinal Fruit", Garamond, serif;
          font-size: 1.5rem;
          color: var(--t-heading);
        }

        .dbs__card-body {
          margin: 0 0 0.75rem;
          color: var(--t-body);
          font-size: 0.92rem;
          line-height: 1.5;
        }

        .dbs__code {
          font-family: ui-monospace, monospace;
          font-size: 0.85em;
          color: var(--a-green);
          background: #2F3641; /* bg-80 */
          padding: 0.1rem 0.3rem;
          border-radius: 0.2rem;
        }

        .dbs__accents {
          display: flex;
          flex-wrap: wrap;
          gap: 0.5rem;
          margin: 0 0 1.5rem;
        }

        .dbs__tag {
          color: var(--tag);
          border: 1px solid var(--tag);
          border-radius: 0.3rem;
          padding: 0.15rem 0.5rem;
          font-size: 0.7rem;
          font-weight: 700;
        }

        .dbs__contrast {
          display: grid;
          gap: 0.3rem;
          max-width: 26rem;
          margin-bottom: 1.5rem;
        }

        .dbs__contrast-row {
          display: grid;
          grid-template-columns: 1.2rem 7rem 3.5rem 1fr;
          gap: 0.5rem;
          align-items: center;
          font-size: 0.72rem;
          color: var(--t-body);
        }

        .dbs__contrast-chip {
          width: 1.2rem;
          height: 1.2rem;
          border-radius: 0.2rem;
          border: 1px solid oklch(100% 0 0 / 16%);
        }

        .dbs__contrast-ratio { font-family: ui-monospace, monospace; text-align: right; }

        .dbs__contrast-tag { font-weight: 700; font-size: 0.62rem; }
        .dbs__contrast-tag[data-v="AAA"] { color: var(--a-green); }
        .dbs__contrast-tag[data-v="AA"] { color: var(--a-green); }
        .dbs__contrast-tag[data-v="AA-lg"] { color: var(--a-yellow); }
        .dbs__contrast-tag[data-v="FAIL"] { color: oklch(68% 0.17 22deg); }

        .dbs__tokens {
          margin-top: 2.5rem;
          display: grid;
          gap: 1rem;
        }

        .dbs__token-label {
          margin: 0 0 0.4rem;
          font-size: 0.62rem;
          font-weight: 700;
          letter-spacing: 0.12em;
          text-transform: uppercase;
          color: oklch(68% 0.07 264deg);
        }

        .dbs__token-row {
          display: flex;
          flex-wrap: wrap;
          gap: 0.9rem;
        }

        .dbs__token {
          display: flex;
          flex-direction: column;
          gap: 0.25rem;
          align-items: flex-start;
        }

        .dbs__token .dbs__swatch + .dbs__swatch { margin-top: -1.65rem; margin-left: 1rem; }

        .dbs__swatch {
          width: 2.4rem;
          height: 2.4rem;
          border-radius: 0.2rem;
          border: 1px solid oklch(100% 0 0 / 16%);
        }

        .dbs__swatch--bright {
          box-shadow: 0 0 0 1px oklch(100% 0 0 / 30%);
        }

        .dbs__token-name {
          font-size: 0.66rem;
          color: oklch(80% 0.04 300deg);
        }

        .dbs__token-name em {
          font-style: normal;
          color: oklch(62% 0.07 277deg);
        }

        .dbs__controls {
          align-self: start;
          position: sticky;
          top: 0;
          max-height: 100vh;
          overflow: auto;
          padding: 1.25rem;
          background: oklch(16% 0.01 264deg);
          border-left: 1px solid oklch(100% 0 0 / 10%);
          font-size: 0.78rem;
        }

        .dbs__h {
          margin: 1.5rem 0 0.5rem;
          font-size: 0.68rem;
          font-weight: 700;
          letter-spacing: 0.12em;
          text-transform: uppercase;
          color: oklch(68% 0.07 264deg);
        }

        .dbs__h:first-child { margin-top: 0; }

        .dbs__row {
          display: grid;
          grid-template-columns: 5.5rem minmax(0, 1fr) 3rem;
          gap: 0.4rem;
          align-items: center;
          margin-bottom: 0.35rem;
        }

        .dbs__row input[type="range"] { width: 100%; accent-color: oklch(76% 0.1 291deg); }

        .dbs__row input[type="text"],
        .dbs__row select {
          grid-column: 2 / 4;
          width: 100%;
          background: oklch(10% 0.01 264deg);
          color: inherit;
          border: 1px solid oklch(100% 0 0 / 18%);
          border-radius: 0.2rem;
          font: inherit;
          padding: 0.15rem 0.3rem;
        }

        .dbs__num { font-family: ui-monospace, monospace; text-align: right; font-size: 0.7rem; }

        .dbs__stop {
          display: grid;
          grid-template-columns: 1.4rem minmax(0, 1fr) 3.2rem;
          gap: 0.35rem;
          align-items: center;
          margin-bottom: 0.3rem;
        }

        .dbs__stop-chip {
          width: 1.4rem; height: 1.4rem;
          border-radius: 0.2rem;
          border: 1px solid oklch(100% 0 0 / 18%);
        }

        .dbs__stop input[type="text"] {
          width: 100%;
          background: oklch(10% 0.01 264deg);
          color: inherit;
          border: 1px solid oklch(100% 0 0 / 18%);
          border-radius: 0.2rem;
          font: inherit;
          padding: 0.15rem 0.3rem;
        }

        .dbs__export {
          margin-top: 1.5rem;
          padding: 0.6rem;
          border-radius: 0.2rem;
          background: oklch(8% 0.01 264deg);
          font-family: ui-monospace, monospace;
          font-size: 0.64rem;
          line-height: 1.5;
          white-space: pre-wrap;
          word-break: break-all;
          color: oklch(80% 0.05 264deg);
        }
      </style>

      <section class="dbs__stage">
        <svg class="dbs__texture" aria-hidden="true" preserveAspectRatio="none">
          <filter id="dbs-tex">
            <feTurbulence
              type="fractalNoise"
              baseFrequency={@tex_frequency}
              numOctaves="1"
              seed={@controls["tex_seed"]}
              result="noise"
            />
            <feColorMatrix
              in="noise"
              type="matrix"
              values={@tex_matrix}
              result="alpha"
            />
            <feFlood flood-color="#ffffff" result="tint" />
            <feComposite in="tint" in2="alpha" operator="in" />
          </filter>
          <rect width="100%" height="100%" fill="#ffffff" filter="url(#dbs-tex)" />
        </svg>

        <div class="dbs__sample">
          <.signature class="dbs__logo" />
          <p class="dbs__eyebrow">
            Dark theme · in situ
            <span class="dbs__chip">contrast = worst case across gradient</span>
          </p>
          <h1 class="dbs__title">A smarter way to remember students' names</h1>
          <p class="dbs__lead">
            The real tokens, applied: heading in warm white, body in neutral, and
            <a href="#" class="dbs__link">links in neutral-50</a>
            that brighten to
            <span class="dbs__inline-hover">neutral-50-bright</span>
            on hover. Surfaces are drawn from the background ramp.
          </p>
          <p class="dbs__meta">
            Secondary text uses neutral-25 — and the verdict below shows it can't carry body copy here.
          </p>

          <div class="dbs__card">
            <p class="dbs__eyebrow">Nested surface · bg-90</p>
            <h2 class="dbs__card-title">Layered surface</h2>
            <p class="dbs__card-body">
              Cards lift on bg-90 / bg-80 so depth reads without introducing new hues.
              Inline code like <code class="dbs__code">def render/1</code>
              borrows a coding accent.
            </p>
            <a href="#" class="dbs__link">Read the case study</a>
          </div>

          <div class="dbs__accents">
            <span class="dbs__tag" style="--tag: var(--a-green)">green</span>
            <span class="dbs__tag" style="--tag: var(--a-yellow)">yellow</span>
            <span class="dbs__tag" style="--tag: var(--a-brown)">brown</span>
            <span class="dbs__tag" style="--tag: var(--a-blue)">blue</span>
          </div>

          <div class="dbs__contrast">
            <p class="dbs__token-label">Readability (worst case vs bg-80)</p>
            <div
              :for={{role, hex, ratio, tag} <- @text_contrast}
              class="dbs__contrast-row"
            >
              <span class="dbs__contrast-chip" style={"background: #{hex}"} />
              <span>{role}</span>
              <span class="dbs__contrast-ratio">{ratio}:1</span>
              <span class="dbs__contrast-tag" data-v={tag}>{tag}</span>
            </div>
          </div>

          <div class="dbs__tokens">
            <div :for={{group, swatches} <- @token_groups} class="dbs__token-group">
              <p class="dbs__token-label">{group}</p>
              <div class="dbs__token-row">
                <div :for={{name, hex, bright} <- swatches} class="dbs__token">
                  <span
                    class="dbs__swatch"
                    style={"background: #{hex}"}
                    title={hex}
                  />
                  <span
                    :if={bright}
                    class="dbs__swatch dbs__swatch--bright"
                    style={"background: #{bright}"}
                    title={bright}
                  />
                  <span class="dbs__token-name">
                    {name}<em :if={bright}> · bright (+0.06C −4%L)</em>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <aside class="dbs__controls">
        <.form for={%{}} as={:sketch} phx-change="update">
          <p class="dbs__h">Base fill</p>
          <.text_row field="base" controls={@controls} />

          <p class="dbs__h">Gradient 1 · {@controls["g1_type"]}</p>
          <.choice_row field="g1_type" controls={@controls} />
          <.geometry field_prefix="g1" controls={@controls} />
          <.choice_row field="g1_blend" controls={@controls} />
          <.range_row field="g1_opacity" controls={@controls} />
          <.stops layer="g1" controls={@controls} />

          <p class="dbs__h">Gradient 2 · {@controls["g2_type"]}</p>
          <.choice_row field="g2_type" controls={@controls} />
          <.geometry field_prefix="g2" controls={@controls} />
          <.choice_row field="g2_blend" controls={@controls} />
          <.range_row field="g2_opacity" controls={@controls} />
          <.stops layer="g2" controls={@controls} />

          <p class="dbs__h">Grain</p>
          <.range_row field="tex_size" controls={@controls} />
          <.range_row field="tex_opacity" controls={@controls} />
          <.choice_row field="tex_blend" controls={@controls} />
          <.range_row field="tex_contrast" controls={@controls} />
          <.range_row field="tex_seed" controls={@controls} />
        </.form>

        <div class="dbs__export">{@css_readout}</div>
      </aside>
    </div>
    """
  end

  ## Components

  attr :field_prefix, :string, required: true
  attr :controls, :map, required: true

  defp geometry(%{field_prefix: prefix} = assigns) do
    assigns =
      assign(assigns, :radial?, assigns.controls["#{prefix}_type"] == "radial")

    ~H"""
    <.range_row
      :if={@radial?}
      field={"#{@field_prefix}_ox"}
      controls={@controls}
      label="Origin X"
    />
    <.range_row
      :if={@radial?}
      field={"#{@field_prefix}_oy"}
      controls={@controls}
      label="Origin Y"
    />
    <.range_row
      :if={@radial?}
      field={"#{@field_prefix}_size"}
      controls={@controls}
      label="Size"
    />
    <.range_row
      :if={!@radial?}
      field={"#{@field_prefix}_angle"}
      controls={@controls}
      label="Angle"
    />
    """
  end

  attr :layer, :string, required: true
  attr :controls, :map, required: true

  defp stops(assigns) do
    ~H"""
    <div :for={n <- 1..5} class="dbs__stop">
      <span
        class="dbs__stop-chip"
        style={"background: #{stop_color(@controls, @layer, n)}"}
      />
      <input
        type="text"
        name={"sketch[#{@layer}_s#{n}_color]"}
        value={@controls["#{@layer}_s#{n}_color"]}
        placeholder="empty = off"
        phx-debounce="200"
      />
      <input
        type="number"
        class="dbs__num"
        name={"sketch[#{@layer}_s#{n}_pos]"}
        value={@controls["#{@layer}_s#{n}_pos"]}
        min="0"
        max="100"
        phx-debounce="200"
      />
    </div>
    """
  end

  attr :field, :string, required: true
  attr :controls, :map, required: true

  defp text_row(assigns) do
    ~H"""
    <div class="dbs__row">
      <span>{@field}</span>
      <input
        type="text"
        name={"sketch[#{@field}]"}
        value={@controls[@field]}
        phx-debounce="200"
      />
    </div>
    """
  end

  attr :field, :string, required: true
  attr :controls, :map, required: true
  attr :label, :string, default: nil

  defp range_row(assigns) do
    {_field, min, max, step} =
      Enum.find(number_fields(), fn {f, _, _, _} -> f == assigns.field end)

    assigns =
      assigns
      |> assign(:min, min)
      |> assign(:max, max)
      |> assign(:step, step)
      |> assign(:display, assigns.label || assigns.field)

    ~H"""
    <div class="dbs__row">
      <span>{@display}</span>
      <input
        type="range"
        name={"sketch[#{@field}]"}
        value={@controls[@field]}
        min={@min}
        max={@max}
        step={@step}
        phx-debounce="60"
      />
      <span class="dbs__num">{@controls[@field]}</span>
    </div>
    """
  end

  attr :field, :string, required: true
  attr :controls, :map, required: true

  defp choice_row(assigns) do
    assigns =
      assign(assigns, :options, Map.fetch!(choice_fields(), assigns.field))

    ~H"""
    <div class="dbs__row">
      <span>{label_for(@field)}</span>
      <select name={"sketch[#{@field}]"}>
        <option
          :for={opt <- @options}
          value={opt}
          selected={opt == @controls[@field]}
        >
          {opt}
        </option>
      </select>
    </div>
    """
  end

  ## Derivation

  defp assign_derived(socket, controls) do
    assign(socket,
      controls: controls,
      token_groups: @token_groups,
      text_contrast: @text_contrast,
      page_style: page_style(controls),
      css_readout: css_readout(controls),
      tex_frequency: format(1 / to_number(controls["tex_size"])),
      tex_matrix: luminance_matrix(to_number(controls["tex_contrast"]))
    )
  end

  defp page_style(controls) do
    {images, blends} = background_layers(controls)

    """
    --dbs-base: #{controls["base"]};
    --dbs-bg: #{images};
    --dbs-blend: #{blends};
    --tex-opacity: #{format(to_number(controls["tex_opacity"]))};
    --tex-blend: #{controls["tex_blend"]};
    """
  end

  # Multiple background images paint first-listed on top; gradient 2 stacks
  # over gradient 1, composited via background-blend-mode.
  defp background_layers(controls) do
    g1 = gradient_css(controls, "g1")
    g2 = gradient_css(controls, "g2")

    layers =
      [{g2, controls["g2_blend"]}, {g1, controls["g1_blend"]}]
      |> Enum.reject(fn {css, _blend} -> is_nil(css) end)

    case layers do
      [] ->
        {"none", "normal"}

      list ->
        {Enum.map_join(list, ", ", fn {css, _} -> css end),
         Enum.map_join(list, ", ", fn {_, blend} -> blend end)}
    end
  end

  defp gradient_css(controls, layer) do
    opacity = to_number(controls["#{layer}_opacity"])
    stops = stop_list(controls, layer)

    cond do
      opacity <= 0 ->
        nil

      length(stops) < 2 ->
        nil

      controls["#{layer}_type"] == "radial" ->
        radial_css(controls, layer, stops)

      true ->
        linear_css(controls, layer, stops)
    end
  end

  defp radial_css(controls, layer, stops) do
    ox = controls["#{layer}_ox"]
    oy = controls["#{layer}_oy"]
    size = controls["#{layer}_size"]
    "radial-gradient(#{size}% #{size}% at #{ox}% #{oy}%, #{stops_str(stops)})"
  end

  defp linear_css(controls, layer, stops) do
    "linear-gradient(#{controls["#{layer}_angle"]}deg, #{stops_str(stops)})"
  end

  defp stops_str(stops) do
    Enum.map_join(stops, ", ", fn {color, pos} -> "#{color} #{pos}%" end)
  end

  defp stop_list(controls, layer) do
    1..5
    |> Enum.map(fn n ->
      {String.trim(controls["#{layer}_s#{n}_color"] || ""),
       controls["#{layer}_s#{n}_pos"]}
    end)
    |> Enum.reject(fn {color, _pos} -> color == "" end)
  end

  defp stop_color(controls, layer, n) do
    case String.trim(controls["#{layer}_s#{n}_color"] || "") do
      "" -> "transparent"
      color -> color
    end
  end

  defp css_readout(controls) do
    {images, blends} = background_layers(controls)

    """
    background-color: #{controls["base"]};
    background-image: #{images};
    background-blend-mode: #{blends};

    /* grain: feTurbulence baseFrequency=#{format(1 / to_number(controls["tex_size"]))} */
    /* seed=#{controls["tex_seed"]} opacity=#{controls["tex_opacity"]} blend=#{controls["tex_blend"]} */
    """
  end

  defp luminance_matrix(contrast) do
    r = format(0.2126 * contrast)
    g = format(0.7152 * contrast)
    b = format(0.0722 * contrast)
    "0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  #{r} #{g} #{b} 0 0"
  end

  ## Param merging

  defp merge(controls, params) do
    Enum.reduce(params, controls, fn {key, value}, acc ->
      cond do
        key in @text_fields -> Map.put(acc, key, value)
        Map.has_key?(@choice_fields, key) -> put_choice(acc, key, value)
        number_field?(key) -> put_number(acc, key, value)
        String.ends_with?(key, "_pos") -> put_number(acc, key, value)
        true -> acc
      end
    end)
  end

  defp put_choice(acc, key, value) do
    if value in Map.fetch!(@choice_fields, key),
      do: Map.put(acc, key, value),
      else: acc
  end

  defp put_number(acc, key, value) do
    case Float.parse(to_string(value)) do
      {n, _} -> Map.put(acc, key, normalize_number(n))
      :error -> acc
    end
  end

  defp normalize_number(n) do
    if n == Float.round(n), do: trunc(n), else: n
  end

  defp number_field?(key),
    do: Enum.any?(@number_fields, fn {f, _, _, _} -> f == key end)

  ## Helpers exposed to components

  defp number_fields, do: @number_fields ++ pos_fields()

  defp pos_fields do
    for layer <- ["g1", "g2"], n <- 1..5, do: {"#{layer}_s#{n}_pos", 0, 100, 1}
  end

  defp choice_fields, do: @choice_fields

  defp label_for("g1_type"), do: "Type"
  defp label_for("g2_type"), do: "Type"
  defp label_for("g1_blend"), do: "Blend"
  defp label_for("g2_blend"), do: "Blend"
  defp label_for("tex_blend"), do: "Blend"
  defp label_for(field), do: field

  defp to_number(value) when is_number(value), do: value

  defp to_number(value) when is_binary(value) do
    case Float.parse(value) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp format(value) when is_integer(value), do: Integer.to_string(value)

  defp format(value) do
    value
    |> :erlang.float_to_binary(decimals: 4)
    |> String.trim_trailing("0")
    |> String.trim_trailing(".")
  end
end
