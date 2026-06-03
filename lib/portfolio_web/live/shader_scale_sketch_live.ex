defmodule PortfolioWeb.ShaderScaleSketchLive do
  @moduledoc false

  use Phoenix.LiveView, layout: false

  @control_specs %{
    shade_count: %{
      default: 9,
      kind: :integer,
      label: "Shade count",
      max: 15,
      min: 3,
      step: "1"
    },
    light_white_point: %{
      default: 94,
      kind: :integer,
      label: "Light white point",
      max: 100,
      min: 70,
      step: "1"
    },
    light_black_point: %{
      default: 36,
      kind: :integer,
      label: "Light black point",
      max: 45,
      min: 0,
      step: "1"
    },
    dark_black_point: %{
      default: 12,
      kind: :integer,
      label: "Dark black point",
      max: 35,
      min: 0,
      step: "1"
    },
    dark_white_point: %{
      default: 82,
      kind: :integer,
      label: "Dark white point",
      max: 100,
      min: 55,
      step: "1"
    },
    curve: %{
      default: "s-curve",
      kind: :choice,
      label: "Step spacing",
      options: ["linear", "ease-in", "ease-out", "s-curve"]
    },
    curve_strength: %{
      default: 1.4,
      label: "Curve strength",
      max: 3,
      min: 0.5,
      step: "0.1"
    },
    mode_position: %{
      default: 50,
      kind: :integer,
      label: "Theme mix",
      max: 100,
      min: 0,
      step: "1"
    },
    tween_curve: %{
      default: "s-curve",
      kind: :choice,
      label: "Mix easing",
      options: ["linear", "s-curve", "ease-in", "ease-out"]
    },
    chroma_profile: %{
      default: "midtones",
      kind: :choice,
      label: "Chroma placement",
      options: ["midtones", "even", "ends"]
    },
    surface_chroma: %{
      default: 0.07,
      label: "Surface C",
      max: 0.18,
      min: 0,
      step: "0.001"
    },
    surface_hue: %{
      default: 247,
      kind: :integer,
      label: "Surface H",
      max: 270,
      min: 220,
      step: "1"
    },
    heading_lightness: %{
      default: 32.8,
      label: "Heading L",
      max: 65,
      min: 10,
      step: "0.1"
    },
    heading_chroma: %{
      default: 0.056,
      label: "Heading C",
      max: 0.18,
      min: 0,
      step: "0.001"
    },
    heading_hue: %{
      default: 48,
      kind: :integer,
      label: "Heading H",
      max: 90,
      min: 0,
      step: "1"
    },
    body_lightness: %{
      default: 40.6,
      label: "Body L",
      max: 70,
      min: 15,
      step: "0.1"
    },
    body_chroma: %{
      default: 0.039,
      label: "Body C",
      max: 0.16,
      min: 0,
      step: "0.001"
    },
    body_hue: %{
      default: 54,
      kind: :integer,
      label: "Body H",
      max: 70,
      min: 35,
      step: "1"
    },
    link_lightness: %{
      default: 46.5,
      label: "Link L",
      max: 75,
      min: 25,
      step: "0.1"
    },
    link_chroma: %{
      default: 0.217,
      label: "Link C",
      max: 0.32,
      min: 0,
      step: "0.001"
    },
    link_hue: %{
      default: 252,
      kind: :integer,
      label: "Link H",
      max: 285,
      min: 210,
      step: "1"
    }
  }

  @impl Phoenix.LiveView
  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:advanced_open?, false)
      |> assign_controls(default_controls())

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("update", %{"shader" => params}, socket) do
    controls = merge_controls(socket.assigns.controls, params)

    {:noreply, assign_controls(socket, controls)}
  end

  def handle_event("update", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle_advanced", _params, socket) do
    {:noreply, update(socket, :advanced_open?, &(!&1))}
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <main class="shader-sketch" style={@page_style} data-shader-scale-sketch>
      <style>
        .shader-sketch {
          min-height: 100vh;
          padding: 2rem;
          background:
            radial-gradient(circle at 70% 16%, oklch(100% 0.04 247deg), transparent 36rem),
            linear-gradient(135deg, oklch(98% 0.03 247deg), oklch(78% 0.12 238deg));
          color: var(--ink);
          font-family: "GT Flexa", "Noto Sans JP", -apple-system, system-ui, sans-serif;
        }

        .shader-sketch__layout {
          display: grid;
          grid-template-columns: minmax(0, 1fr) 24rem;
          gap: 1.5rem;
          max-width: 92rem;
          margin-inline: auto;
        }

        .shader-sketch__canvas {
          display: grid;
          gap: 1rem;
          align-content: start;
        }

        .shader-sketch__intro {
          max-width: 52rem;
        }

        .shader-sketch__eyebrow,
        .shader-sketch__section-title {
          margin: 0;
          color: var(--soft-ink);
          font-size: 0.72rem;
          font-weight: 750;
          letter-spacing: 0.12em;
          line-height: 1.2;
          text-transform: uppercase;
        }

        .shader-sketch__title {
          max-width: 12ch;
          margin: 0.45rem 0 0;
          color: var(--ink);
          font-family: "Cardinal Fruit", Garamond, "Times New Roman", serif;
          font-size: 4.7rem;
          line-height: 0.9;
        }

        .shader-sketch__lead {
          max-width: 46rem;
          margin: 1rem 0 0;
          color: var(--ink);
          font-size: 1.15rem;
          line-height: 1.45;
        }

        .shader-sketch__reserved {
          display: grid;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          gap: 0.75rem;
        }

        .shader-sketch__material,
        .shader-sketch__panel,
        .shader-sketch__controls {
          border: 1px solid rgb(0 0 0 / 12%);
          border-radius: 0.35rem;
          background: rgb(255 255 255 / 42%);
          box-shadow: 0 1px 3px rgb(0 0 0 / 10%);
          backdrop-filter: blur(16px);
        }

        .shader-sketch__material {
          min-height: 9rem;
          padding: 0.85rem;
        }

        .shader-sketch__material[data-tone="white"] {
          background: var(--absolute-white);
        }

        .shader-sketch__material[data-tone="black"] {
          background: var(--absolute-black);
          color: var(--absolute-white);
        }

        .shader-sketch__material-title {
          margin: 0;
          font-size: 0.82rem;
          font-weight: 800;
          line-height: 1.2;
        }

        .shader-sketch__material-note {
          margin: 0.45rem 0 0;
          font-size: 0.72rem;
          line-height: 1.35;
        }

        .shader-sketch__grade-map {
          display: grid;
          gap: 0.8rem;
        }

        .shader-sketch__grade-grid {
          display: grid;
          grid-template-columns: repeat(3, minmax(0, 1fr));
          gap: 0.75rem;
        }

        .shader-sketch__grade-card {
          display: grid;
          grid-template-rows: auto auto minmax(9rem, 1fr) auto;
          gap: 0.55rem;
          padding: 0.7rem;
          border: 1px solid rgb(0 0 0 / 10%);
          border-radius: 0.3rem;
          background: rgb(255 255 255 / 38%);
        }

        .shader-sketch__grade-card[data-mode="dark"] {
          background: rgb(0 0 0 / 58%);
          color: white;
        }

        .shader-sketch__grade-card[data-mode="current"] {
          background: var(--current-surface);
          color: var(--current-ink);
        }

        .shader-sketch__grade-label {
          margin: 0;
          font-size: 0.78rem;
          font-weight: 800;
          line-height: 1.25;
        }

        .shader-sketch__mini-ramp {
          display: grid;
          grid-template-columns: repeat(var(--shade-count), minmax(0, 1fr));
          gap: 0.15rem;
        }

        .shader-sketch__mini-ramp-chip {
          min-height: 1rem;
          border: 1px solid rgb(0 0 0 / 12%);
          border-radius: 0.16rem;
          background: var(--chip-color);
        }

        .shader-sketch__grade-sample {
          display: grid;
          gap: 0.65rem;
          align-content: center;
          min-height: 9rem;
          padding: 0.8rem;
          border-radius: 0.25rem;
          background: var(--grade-background);
          color: var(--grade-body);
          box-shadow: inset 0 0 0 1px rgb(255 255 255 / 14%);
        }

        .shader-sketch__grade-title {
          margin: 0;
          font-family: "Cardinal Fruit", Garamond, "Times New Roman", serif;
          color: var(--grade-heading);
          font-size: 2rem;
          line-height: 0.95;
        }

        .shader-sketch__grade-body {
          margin: 0;
          max-width: 28ch;
          font-size: 0.78rem;
          line-height: 1.35;
        }

        .shader-sketch__grade-link {
          width: max-content;
          border-bottom: 1px solid currentcolor;
          color: var(--grade-link);
          font-size: 0.78rem;
          font-weight: 800;
          line-height: 1.2;
          text-decoration: none;
        }

        .shader-sketch__grade-muted {
          margin: 0;
          color: var(--grade-muted);
          font-size: 0.66rem;
          line-height: 1.35;
        }

        .shader-sketch__grade-rule {
          width: 100%;
          height: 1px;
          background: var(--grade-rule);
        }

        .shader-sketch__grade-meta {
          margin: 0;
          font-size: 0.68rem;
          line-height: 1.35;
        }

        .shader-sketch__panel {
          display: grid;
          gap: 0.8rem;
          padding: 0.9rem;
        }

        .shader-sketch__ramps {
          display: grid;
          gap: 1rem;
        }

        .shader-sketch__ramp {
          display: grid;
          gap: 0.5rem;
        }

        .shader-sketch__swatches {
          display: grid;
          grid-template-columns: repeat(var(--shade-count), minmax(4.25rem, 1fr));
          gap: 0.4rem;
          overflow-x: auto;
        }

        .shader-sketch__swatch {
          min-height: 8.25rem;
          padding: 0.55rem;
          border: 1px solid rgb(0 0 0 / 10%);
          border-radius: 0.25rem;
          color: var(--swatch-ink);
          box-shadow: inset 0 0 0 1px rgb(255 255 255 / 18%);
        }

        .shader-sketch__swatch-name {
          margin: 0;
          font-size: 0.68rem;
          font-weight: 800;
          line-height: 1.2;
        }

        .shader-sketch__swatch-value,
        .shader-sketch__swatch-step {
          margin: 0.35rem 0 0;
          font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
          font-size: 0.62rem;
          line-height: 1.25;
        }

        .shader-sketch__badges {
          display: flex;
          flex-wrap: wrap;
          gap: 0.22rem;
          margin-top: 0.55rem;
        }

        .shader-sketch__badge {
          padding: 0.12rem 0.25rem;
          border: 1px solid currentcolor;
          border-radius: 0.2rem;
          background: rgb(255 255 255 / 22%);
          font-size: 0.56rem;
          font-weight: 800;
          line-height: 1.15;
        }

        .shader-sketch__controls {
          position: sticky;
          top: 1rem;
          align-self: start;
          max-height: calc(100vh - 2rem);
          overflow: auto;
          padding: 1rem;
        }

        .shader-sketch__controls-title {
          margin: 0;
          color: var(--ink);
          font-family: "Cardinal Fruit", Garamond, "Times New Roman", serif;
          font-size: 2.2rem;
          line-height: 0.95;
        }

        .shader-sketch__controls-note {
          margin: 0.5rem 0 0;
          color: var(--soft-ink);
          font-size: 0.78rem;
          line-height: 1.35;
        }

        .shader-sketch__stack {
          display: grid;
          gap: 0.8rem;
          margin-top: 1rem;
        }

        .shader-sketch__field-group {
          display: grid;
          gap: 0.55rem;
          padding: 0.7rem;
          border: 1px solid rgb(0 0 0 / 10%);
          border-radius: 0.25rem;
        }

        .shader-sketch__legend {
          padding-inline: 0.25rem;
          color: var(--soft-ink);
          font-size: 0.76rem;
          font-weight: 800;
          letter-spacing: 0.08em;
          text-transform: uppercase;
        }

        .shader-sketch__advanced {
          display: grid;
          gap: 0.65rem;
          padding: 0.7rem;
          border: 1px solid rgb(0 0 0 / 10%);
          border-radius: 0.25rem;
        }

        .shader-sketch__advanced-toggle {
          cursor: pointer;
          width: 100%;
          border: 0;
          background: transparent;
          color: var(--soft-ink);
          font-size: 0.76rem;
          font-weight: 800;
          letter-spacing: 0.08em;
          text-align: left;
          text-transform: uppercase;
        }

        .shader-sketch__advanced-toggle::before {
          content: "▸";
          display: inline-block;
          width: 1rem;
        }

        .shader-sketch__advanced-toggle[aria-expanded="true"]::before {
          content: "▾";
        }

        .shader-sketch__advanced-stack {
          display: grid;
          gap: 0.75rem;
          margin-top: 0.75rem;
        }

        .shader-sketch__slider {
          display: grid;
          grid-template-columns: 8rem minmax(0, 1fr) 3.6rem;
          gap: 0.5rem;
          align-items: center;
          color: var(--ink);
          font-size: 0.74rem;
        }

        .shader-sketch__slider input {
          width: 100%;
          accent-color: oklch(46.5% 0.217 252deg);
        }

        .shader-sketch__select {
          width: 100%;
          border: 1px solid rgb(0 0 0 / 16%);
          border-radius: 0.25rem;
          background: rgb(255 255 255 / 62%);
          color: var(--ink);
          font: inherit;
        }

        .shader-sketch__number {
          font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
          text-align: right;
        }

        @media (max-width: 68rem) {
          .shader-sketch {
            padding: 1rem;
          }

          .shader-sketch__layout,
          .shader-sketch__reserved,
          .shader-sketch__grade-grid {
            grid-template-columns: 1fr;
          }

          .shader-sketch__title {
            font-size: 3.4rem;
          }

          .shader-sketch__controls {
            position: static;
            max-height: none;
          }
        }
      </style>

      <div class="shader-sketch__layout">
        <section class="shader-sketch__canvas">
          <header class="shader-sketch__intro">
            <p class="shader-sketch__eyebrow">Color grade system sketch</p>
            <h1 class="shader-sketch__title">
              Role palettes with diagnostic ramps
            </h1>
            <p class="shader-sketch__lead">
              Tune white and black points, surface color, reading ink, and action ink
              as separate relationships, then scrub the in-between state. The ramps
              show whether the supporting scale still behaves.
            </p>
          </header>

          <section
            class="shader-sketch__reserved"
            aria-label="Reserved endpoint preview"
          >
            <article class="shader-sketch__material" data-tone="white">
              <h2 class="shader-sketch__material-title">Absolute white</h2>
              <p class="shader-sketch__material-note">
                Reserved endpoint. Use as a special material, not the normal page ceiling.
              </p>
            </article>
            <article class="shader-sketch__material" data-tone="black">
              <h2 class="shader-sketch__material-title">Absolute black</h2>
              <p class="shader-sketch__material-note">
                Reserved endpoint. Useful for masks, hard depth, or rare full-stop contrast.
              </p>
            </article>
            <article class="shader-sketch__material">
              <h2 class="shader-sketch__material-title">Current state</h2>
              <p class="shader-sketch__material-note">
                Mode position: {@controls.mode_position}%.
                Tween curve: {@controls.tween_curve}.
              </p>
            </article>
          </section>

          <section class="shader-sketch__panel shader-sketch__grade-map">
            <h2 class="shader-sketch__section-title">Grade keyframes</h2>
            <div class="shader-sketch__grade-grid">
              <article
                :for={grade <- @grade_cards}
                class="shader-sketch__grade-card"
                data-mode={grade.mode}
              >
                <h3 class="shader-sketch__grade-label">{grade.label}</h3>
                <div class="shader-sketch__mini-ramp" aria-label={grade.ramp_label}>
                  <span
                    :for={chip <- grade.chips}
                    class="shader-sketch__mini-ramp-chip"
                    style={chip.style}
                  >
                  </span>
                </div>
                <div class="shader-sketch__grade-sample" style={grade.style}>
                  <p class="shader-sketch__grade-title">The quiet page</p>
                  <p class="shader-sketch__grade-body">
                    Body text, links, rules, and muted details need to survive
                    the grade together.
                  </p>
                  <a class="shader-sketch__grade-link" href="#">
                    Read the self portrait
                  </a>
                  <div class="shader-sketch__grade-rule"></div>
                  <p class="shader-sketch__grade-muted">
                    Metadata, dates, and soft labels.
                  </p>
                </div>
                <p class="shader-sketch__grade-meta">{grade.meta}</p>
              </article>
            </div>
          </section>

          <section class="shader-sketch__panel">
            <h2 class="shader-sketch__section-title">Generated ramps</h2>
            <div class="shader-sketch__ramps">
              <.ramp mode={:light} title="Light keyframe" shades={@light_shades} />
              <.ramp
                mode={:current}
                title="Current tween state"
                shades={@current_shades}
              />
              <.ramp mode={:dark} title="Dark keyframe" shades={@dark_shades} />
            </div>
          </section>
        </section>

        <aside class="shader-sketch__controls">
          <h2 class="shader-sketch__controls-title">Role controls</h2>
          <p class="shader-sketch__controls-note">
            Tune endpoints, surface color, reading ink, and action ink separately. The
            generated ramps stay below as diagnostics.
          </p>
          <.form
            id="shader-scale-controls"
            for={%{}}
            as={:shader}
            phx-change="update"
          >
            <div class="shader-sketch__stack">
              <fieldset class="shader-sketch__field-group">
                <legend class="shader-sketch__legend">Theme mix</legend>
                <.range_input field={:mode_position} controls={@controls} />
              </fieldset>

              <fieldset class="shader-sketch__field-group">
                <legend class="shader-sketch__legend">Surface color</legend>
                <.range_input field={:surface_chroma} controls={@controls} />
                <.range_input field={:surface_hue} controls={@controls} />
              </fieldset>

              <fieldset class="shader-sketch__field-group">
                <legend class="shader-sketch__legend">Reading ink</legend>
                <.range_input field={:heading_lightness} controls={@controls} />
                <.range_input field={:heading_chroma} controls={@controls} />
                <.range_input field={:heading_hue} controls={@controls} />
                <.range_input field={:body_lightness} controls={@controls} />
                <.range_input field={:body_chroma} controls={@controls} />
                <.range_input field={:body_hue} controls={@controls} />
              </fieldset>

              <fieldset class="shader-sketch__field-group">
                <legend class="shader-sketch__legend">Action ink</legend>
                <.range_input field={:link_lightness} controls={@controls} />
                <.range_input field={:link_chroma} controls={@controls} />
                <.range_input field={:link_hue} controls={@controls} />
              </fieldset>

              <section class="shader-sketch__advanced">
                <button
                  type="button"
                  class="shader-sketch__advanced-toggle"
                  phx-click="toggle_advanced"
                  aria-expanded={to_string(@advanced_open?)}
                  aria-controls="shader-scale-advanced-model"
                >
                  Advanced model
                </button>
                <div
                  :if={@advanced_open?}
                  id="shader-scale-advanced-model"
                  class="shader-sketch__advanced-stack"
                >
                  <fieldset class="shader-sketch__field-group">
                    <legend class="shader-sketch__legend">Structure</legend>
                    <.range_input field={:shade_count} controls={@controls} />
                  </fieldset>

                  <fieldset class="shader-sketch__field-group">
                    <legend class="shader-sketch__legend">Scale endpoints</legend>
                    <.range_input field={:light_white_point} controls={@controls} />
                    <.range_input field={:light_black_point} controls={@controls} />
                    <.range_input field={:dark_black_point} controls={@controls} />
                    <.range_input field={:dark_white_point} controls={@controls} />
                  </fieldset>

                  <fieldset class="shader-sketch__field-group">
                    <legend class="shader-sketch__legend">Ramp shape</legend>
                    <.choice_input field={:curve} controls={@controls} />
                    <.range_input field={:curve_strength} controls={@controls} />
                    <.choice_input field={:chroma_profile} controls={@controls} />
                  </fieldset>

                  <fieldset class="shader-sketch__field-group">
                    <legend class="shader-sketch__legend">Mode tween</legend>
                    <.choice_input field={:tween_curve} controls={@controls} />
                  </fieldset>
                </div>
              </section>
            </div>
          </.form>
        </aside>
      </div>
    </main>
    """
  end

  attr :shades, :list, required: true
  attr :mode, :atom, required: true
  attr :title, :string, required: true

  @spec ramp(map()) :: Phoenix.LiveView.Rendered.t()
  def ramp(assigns) do
    ~H"""
    <section class="shader-sketch__ramp" data-ramp={@mode}>
      <h3 class="shader-sketch__section-title">{@title}</h3>
      <div class="shader-sketch__swatches">
        <article
          :for={shade <- @shades}
          class="shader-sketch__swatch"
          style={shade.style}
        >
          <p class="shader-sketch__swatch-name">{shade.name}</p>
          <p class="shader-sketch__swatch-value">{shade.value}</p>
          <p class="shader-sketch__swatch-step">{shade.step_label}</p>
          <div class="shader-sketch__badges">
            <span :for={badge <- shade.badges} class="shader-sketch__badge">
              {badge}
            </span>
          </div>
        </article>
      </div>
    </section>
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
    <label class="shader-sketch__slider">
      <span>{@label}</span>
      <input
        id={@field_name}
        name={"shader[#{@field_name}]"}
        type="range"
        min={@min}
        max={@max}
        step={@step}
        value={@value}
        phx-debounce="80"
      />
      <span class="shader-sketch__number">{@value}</span>
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
    <label class="shader-sketch__slider">
      <span>{@label}</span>
      <select
        id={@field_name}
        name={"shader[#{@field_name}]"}
        class="shader-sketch__select"
      >
        <option :for={option <- @options} value={option} selected={option == @value}>
          {option}
        </option>
      </select>
      <span class="shader-sketch__number">{@value}</span>
    </label>
    """
  end

  defp assign_controls(socket, controls) do
    light_shades = build_ramp(:light, controls)
    current_shades = build_ramp(:current, controls)
    dark_shades = build_ramp(:dark, controls)

    [current_surface | _remaining_current_shades] = current_shades

    assign(socket,
      controls: controls,
      current_shades: current_shades,
      dark_shades: dark_shades,
      grade_cards:
        build_grade_cards(controls, light_shades, current_shades, dark_shades),
      light_shades: light_shades,
      page_style:
        "--shade-count: #{controls.shade_count}; --ink: oklch(27% 0.04 54deg); --soft-ink: oklch(40% 0.04 54deg); --absolute-white: oklch(100% 0 0deg); --absolute-black: oklch(0% 0 0deg); --current-surface: #{current_surface.value}; --current-ink: #{swatch_ink(current_surface)};"
    )
  end

  defp build_ramp(mode, controls) do
    colors =
      0..(controls.shade_count - 1)
      |> Enum.map(fn index ->
        amount = normalized_step(index, controls.shade_count)
        color = diagnostic_ramp_color(mode, controls, index, amount)

        color
        |> Map.put(:amount, amount)
        |> Map.put(:index, index)
      end)

    light_surface = Enum.max_by(colors, & &1.lightness)
    dark_surface = Enum.min_by(colors, & &1.lightness)

    Enum.map(colors, fn color ->
      previous_color =
        if color.index == 0 do
          nil
        else
          Enum.at(colors, color.index - 1)
        end

      %{
        badges: shade_badges(color, light_surface, dark_surface),
        chroma: color.chroma,
        hue: color.hue,
        lightness: color.lightness,
        name: shade_name(mode, color.index),
        step_label:
          step_label(color.lightness * 100, previous_lightness(previous_color)),
        style:
          "background: #{color.value}; --swatch-ink: #{swatch_ink(color)};",
        value: color.value
      }
    end)
  end

  defp diagnostic_ramp_color(:current, controls, index, amount) do
    progress =
      controls.mode_position
      |> Kernel./(100)
      |> curve(controls.tween_curve, 1.4)

    light_color = diagnostic_ramp_color(:light, controls, index, amount)
    dark_color = diagnostic_ramp_color(:dark, controls, index, amount)

    interpolate_color(light_color, dark_color, progress)
  end

  defp diagnostic_ramp_color(mode, controls, _index, amount) do
    ramp_color(mode, controls, amount)
  end

  defp build_grade_cards(controls, light_shades, current_shades, dark_shades) do
    [
      grade_card(:light, "Light keyframe", controls, light_shades),
      grade_card(:current, "Current tween", controls, current_shades),
      grade_card(:dark, "Dark keyframe", controls, dark_shades)
    ]
  end

  defp grade_card(mode, label, controls, shades) do
    roles = grade_roles(mode, controls)
    surface = Map.fetch!(roles, :surface)
    heading = Map.fetch!(roles, :heading)
    body = Map.fetch!(roles, :body)
    muted = Map.fetch!(roles, :muted)
    link = Map.fetch!(roles, :link)
    rule = Map.fetch!(roles, :rule)

    %{
      chips: Enum.map(shades, &%{style: "--chip-color: #{&1.value};"}),
      label: label,
      meta: grade_meta(mode, controls),
      mode: mode,
      ramp_label: "#{label} mini ramp",
      style:
        "--grade-background: #{surface.value}; --grade-heading: #{heading.value}; --grade-body: #{body.value}; --grade-muted: #{muted.value}; --grade-link: #{link.value}; --grade-rule: #{rule.value};"
    }
  end

  defp grade_roles(:light, controls) do
    %{
      body:
        role_color(
          controls.body_lightness,
          controls.body_chroma,
          controls.body_hue
        ),
      heading:
        role_color(
          controls.heading_lightness,
          controls.heading_chroma,
          controls.heading_hue
        ),
      link:
        role_color(
          controls.link_lightness,
          controls.link_chroma,
          controls.link_hue
        ),
      muted:
        role_color(
          clamp(controls.body_lightness + 10.4, 0, 100),
          controls.body_chroma * 0.82,
          controls.body_hue
        ),
      rule:
        role_color(
          clamp(controls.link_lightness + 12.2, 0, 100),
          controls.link_chroma * 0.67,
          controls.link_hue
        ),
      surface:
        role_color(
          controls.light_white_point,
          controls.surface_chroma,
          controls.surface_hue
        )
    }
  end

  defp grade_roles(:dark, controls) do
    %{
      body: role_color(78, controls.body_chroma * 0.67, controls.body_hue),
      heading:
        role_color(88, controls.heading_chroma * 0.72, controls.heading_hue),
      link: role_color(72, controls.link_chroma * 0.74, controls.link_hue),
      muted: role_color(64, controls.body_chroma * 0.56, controls.body_hue),
      rule: role_color(46, controls.link_chroma * 0.42, controls.link_hue),
      surface:
        role_color(
          controls.dark_black_point,
          controls.surface_chroma * 0.4,
          normalize_hue(controls.surface_hue + 21)
        )
    }
  end

  defp grade_roles(:current, controls) do
    progress =
      controls.mode_position
      |> Kernel./(100)
      |> curve(controls.tween_curve, 1.4)

    light_roles = grade_roles(:light, controls)
    dark_roles = grade_roles(:dark, controls)

    Map.new(Map.keys(light_roles), fn role ->
      light_color = Map.fetch!(light_roles, role)
      dark_color = Map.fetch!(dark_roles, role)

      {role, interpolate_color(light_color, dark_color, progress)}
    end)
  end

  defp grade_meta(:light, controls) do
    "white #{format_number(controls.light_white_point)} / black #{format_number(controls.light_black_point)} / body #{format_number(controls.body_lightness)} / link #{format_number(controls.link_lightness)}"
  end

  defp grade_meta(:dark, controls) do
    "black #{format_number(controls.dark_black_point)} / white #{format_number(controls.dark_white_point)} / derived color"
  end

  defp grade_meta(:current, controls) do
    "mode #{controls.mode_position}% / #{controls.tween_curve}"
  end

  defp normalized_step(_index, 1), do: 0
  defp normalized_step(index, count), do: index / (count - 1)

  defp ramp_color(mode, controls, amount) do
    curved_amount = curve(amount, controls.curve, controls.curve_strength)
    lightness = ramp_lightness(mode, controls, curved_amount)

    shade_color(lightness, grade_for(mode, controls), amount, controls)
  end

  defp grade_for(:light, controls) do
    surface =
      :light
      |> grade_roles(controls)
      |> Map.fetch!(:surface)

    %{
      chroma: surface.chroma,
      hue: surface.hue
    }
  end

  defp grade_for(:dark, controls) do
    surface =
      :dark
      |> grade_roles(controls)
      |> Map.fetch!(:surface)

    %{
      chroma: surface.chroma,
      hue: surface.hue
    }
  end

  defp ramp_lightness(:light, controls, amount) do
    lerp(controls.light_white_point, controls.light_black_point, amount)
  end

  defp ramp_lightness(:dark, controls, amount) do
    lerp(controls.dark_black_point, controls.dark_white_point, amount)
  end

  defp previous_lightness(nil), do: nil
  defp previous_lightness(color), do: color.lightness * 100

  defp curve(amount, "ease-in", strength), do: :math.pow(amount, strength)

  defp curve(amount, "ease-out", strength),
    do: 1 - :math.pow(1 - amount, strength)

  defp curve(amount, "s-curve", strength) do
    if amount < 0.5 do
      :math.pow(amount * 2, strength) / 2
    else
      1 - :math.pow((1 - amount) * 2, strength) / 2
    end
  end

  defp curve(amount, _curve, _strength), do: amount

  defp shade_color(lightness, grade, amount, controls) do
    chroma = grade.chroma * chroma_weight(amount, controls)

    role_color(lightness, chroma, grade.hue)
  end

  defp role_color(lightness, chroma, hue) do
    %{
      chroma: chroma,
      hue: normalize_hue(hue),
      lightness: lightness / 100,
      value:
        "oklch(#{format_percent(lightness)} #{format_number(chroma)} #{format_degrees(normalize_hue(hue))})"
    }
  end

  defp chroma_weight(_amount, %{chroma_profile: "even"}), do: 1

  defp chroma_weight(amount, _controls) when amount == 0, do: 1

  defp chroma_weight(amount, %{chroma_profile: "ends"}) do
    endness = abs(0.5 - amount) * 2

    0.25 + 0.75 * endness
  end

  defp chroma_weight(amount, _controls) do
    midtone = 1 - abs(0.5 - amount) * 2

    0.25 + 0.75 * midtone
  end

  defp interpolate_color(light_color, dark_color, progress) do
    lightness = lerp(light_color.lightness, dark_color.lightness, progress)
    chroma = lerp(light_color.chroma, dark_color.chroma, progress)
    hue = interpolate_hue(light_color.hue, dark_color.hue, progress)

    %{
      chroma: chroma,
      hue: hue,
      lightness: lightness,
      value:
        "oklch(#{format_percent(lightness * 100)} #{format_number(chroma)} #{format_degrees(hue)})"
    }
  end

  defp interpolate_hue(from_hue, to_hue, progress) do
    delta = to_hue - from_hue

    delta =
      cond do
        delta > 180 -> delta - 360
        delta < -180 -> delta + 360
        true -> delta
      end

    from_hue
    |> Kernel.+(delta * progress)
    |> normalize_hue()
  end

  defp normalize_hue(hue) when hue < 0, do: normalize_hue(hue + 360)
  defp normalize_hue(hue) when hue >= 360, do: normalize_hue(hue - 360)
  defp normalize_hue(hue), do: hue

  defp lerp(from_value, to_value, progress) do
    from_value + (to_value - from_value) * progress
  end

  defp shade_badges(color, light_surface, dark_surface) do
    [
      "BG",
      text_badge("Text on light", color, light_surface),
      text_badge("Text on dark", color, dark_surface)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp text_badge(label, text_color, background_color) do
    if wcag_contrast(text_color, background_color) >= 4.5 do
      label
    else
      nil
    end
  end

  defp shade_name(:light, index), do: "L#{index + 1}"
  defp shade_name(:current, index), do: "C#{index + 1}"
  defp shade_name(:dark, index), do: "D#{index + 1}"

  defp step_label(_lightness, nil), do: "anchor"

  defp step_label(lightness, previous_lightness) do
    delta = abs(lightness - previous_lightness)

    "ΔL #{format_number(delta)}"
  end

  defp swatch_ink(color) do
    if relative_luminance(color) > 0.42 do
      "oklch(22% 0.035 54deg)"
    else
      "oklch(96% 0.015 247deg)"
    end
  end

  defp wcag_contrast(text_color, background_color) do
    text_luminance = relative_luminance(text_color)
    background_luminance = relative_luminance(background_color)
    lighter = max(text_luminance, background_luminance)
    darker = min(text_luminance, background_luminance)

    (lighter + 0.05) / (darker + 0.05)
  end

  defp relative_luminance(color) do
    rgb = oklch_to_srgb(color)
    linear_rgb = srgb_to_linear_rgb(rgb)

    0.2126 * linear_rgb.red + 0.7152 * linear_rgb.green +
      0.0722 * linear_rgb.blue
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
    normalized_controls = normalize_controls(controls)

    Enum.reduce(@control_specs, normalized_controls, fn {field, spec},
                                                        merged_controls ->
      field_name = Atom.to_string(field)
      current_value = Map.fetch!(normalized_controls, field)

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

  defp normalize_controls(controls) do
    Map.new(@control_specs, fn {field, spec} ->
      {field, Map.get(controls, field, spec.default)}
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
