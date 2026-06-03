defmodule PortfolioWeb.PaletteComparisonLive do
  @moduledoc false
  use Phoenix.LiveView, layout: false

  # Light: finalized sketch values
  @light %{
    id: "light",
    label: "Light",
    logo_src: "/images/big-name-light.svg",
    has_turbulence: true,
    vars: [
      {"--surface-primary", "oklch(100% 0.079 230.2deg)"},
      {"--surface-secondary", "oklch(81.3% 0.144 238deg)"},
      {"--surface-highlight", "oklch(100% 0.147 268.8deg)"},
      {"--surface-shadow", "oklch(64.8% 0.095 360deg)"},
      {"--text-heading", "oklch(22.6% 0.028 48deg)"},
      {"--text-body", "oklch(15.9% 0.053 54deg)"},
      {"--text-link", "oklch(58.7% 0.146 252deg)"},
      {"--text-deemphasized", "oklch(40.6% 0.039 54deg)"}
    ],
    gradient:
      "radial-gradient(circle at 19% 20%, var(--surface-primary) 0%, color-mix(in oklch, var(--surface-primary) 49%, var(--surface-secondary)) 51%, var(--surface-secondary) 138%)",
    notes: nil
  }

  # Dark: current system values mapped to the same semantic slots
  @dark %{
    id: "dark",
    label: "Dark",
    logo_src: "/images/big-name-dark.svg",
    has_turbulence: false,
    vars: [
      {"--surface-primary", "oklch(14% 0.034 38deg)"},
      {"--surface-secondary", "oklch(0% 0 0deg)"},
      {"--surface-highlight", "oklch(41.84% 0.038 261.51deg)"},
      {"--surface-shadow", "oklch(5% 0.012 35deg)"},
      {"--text-heading", "oklch(90.76% 0.0184 316.61deg)"},
      {"--text-body", "oklch(88.73% 0.056 324.15deg)"},
      {"--text-link", "oklch(76.32% 0.1 291.05deg)"},
      {"--text-deemphasized", "oklch(68.67% 0.095 276.77deg)"}
    ],
    gradient:
      "radial-gradient(140.76% 178.27% at 91.11% 4.14%, oklch(0% 0 0deg) 0%, oklch(9.8% 0.021 39deg) 31%, oklch(15% 0.034 38deg) 57%, oklch(13.5% 0.029 36deg) 77%, oklch(12.5% 0.025 32deg) 100%)",
    notes: "Link: dusk-400 (pending review) · No turbulence — gradient geometry is the intentional dark-mode approach"
  }

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, light: @light, dark: @dark)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="pc">
      <style>
        .pc {
          background: oklch(11% 0.012 264deg);
          font-family: "GT Flexa", "Noto Sans JP", system-ui, sans-serif;
          font-weight: 350;
          min-height: 100vh;
        }

        .pc__header {
          padding: 1rem 2rem;
          border-bottom: 1px solid oklch(100% 0 0deg / 8%);
        }

        .pc__header-title {
          color: oklch(88% 0.056 324deg);
          font-size: 0.72rem;
          font-weight: 700;
          letter-spacing: 0.14em;
          text-transform: uppercase;
        }

        .pc__header-desc {
          margin-top: 0.2rem;
          color: oklch(68% 0.07 264deg);
          font-size: 0.68rem;
        }

        .pc__grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          min-height: calc(100vh - 3.5rem);
        }

        @media (max-width: 860px) {
          .pc__grid { grid-template-columns: 1fr; }
          .pc__panel + .pc__panel { border-left: none; border-top: 1px solid oklch(100% 0 0deg / 8%); }
        }

        .pc__panel + .pc__panel {
          border-left: 1px solid oklch(100% 0 0deg / 8%);
        }

        .pc__panel {
          position: relative;
          isolation: isolate;
          padding: 2.5rem 2.5rem 3rem;
          min-height: 100vh;
        }

        .pc__turbulence-layer {
          position: absolute;
          inset: 0;
          z-index: -1;
          width: 100%;
          height: 100%;
          pointer-events: none;
        }

        .pc__content {
          position: relative;
          z-index: 1;
          max-width: 32rem;
        }

        .pc__mode-tag {
          display: inline-block;
          padding: 0.18rem 0.45rem;
          border: 1px solid currentcolor;
          border-radius: 0.2rem;
          color: var(--text-deemphasized);
          font-size: 0.65rem;
          font-weight: 700;
          letter-spacing: 0.12em;
          text-transform: uppercase;
          margin-bottom: 2.5rem;
        }

        .pc__logo {
          display: block;
          max-width: 100%;
          height: auto;
          margin-bottom: 3rem;
        }

        .pc__eyebrow {
          color: var(--text-deemphasized);
          font-size: 0.72rem;
          font-weight: 700;
          letter-spacing: 0.14em;
          text-transform: uppercase;
          margin-bottom: 0.75rem;
        }

        .pc__title {
          color: var(--text-heading);
          font-family: "Cardinal Fruit", Garamond, "Times New Roman", serif;
          font-size: 3.5rem;
          font-weight: 400;
          line-height: 0.9;
          max-width: 10ch;
          margin-bottom: 1.5rem;
        }

        .pc__body {
          color: var(--text-body);
          font-size: 1.1rem;
          line-height: 1.5;
          margin-bottom: 1.25rem;
        }

        .pc__link {
          display: inline-flex;
          min-height: 44px;
          align-items: center;
          border-bottom: 1px solid currentcolor;
          color: var(--text-link);
          font-size: 1rem;
          font-weight: 650;
          text-decoration: none;
          margin-bottom: 2.5rem;
        }

        .pc__tiles {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 0.5rem;
          margin-bottom: 2rem;
        }

        .pc__tile {
          padding: 0.7rem;
          border: 1px solid oklch(0% 0 0deg / 10%);
          border-radius: 0.25rem;
        }

        .pc__tile-label {
          display: block;
          color: var(--text-deemphasized);
          font-size: 0.6rem;
          font-weight: 700;
          letter-spacing: 0.1em;
          text-transform: uppercase;
          margin-bottom: 0.45rem;
        }

        .pc__tile-heading {
          display: block;
          color: var(--text-heading);
          font-family: "Cardinal Fruit", serif;
          font-size: 0.95rem;
          margin-bottom: 0.3rem;
        }

        .pc__tile-body {
          color: var(--text-body);
          font-size: 0.68rem;
          line-height: 1.35;
          margin-bottom: 0.35rem;
        }

        .pc__tile-link {
          display: inline-block;
          color: var(--text-link);
          font-size: 0.68rem;
          font-weight: 700;
          border-bottom: 1px solid currentcolor;
          text-decoration: none;
        }

        .pc__tokens {
          margin-top: 1rem;
        }

        .pc__tokens summary {
          cursor: pointer;
          color: var(--text-deemphasized);
          font-size: 0.68rem;
          font-weight: 700;
          letter-spacing: 0.1em;
          text-transform: uppercase;
          list-style: none;
          margin-bottom: 0.5rem;
        }

        .pc__tokens summary::before {
          content: "▶ ";
          font-size: 0.55rem;
        }

        details[open] .pc__tokens summary::before {
          content: "▼ ";
        }

        .pc__token-block {
          padding: 0.75rem;
          border-radius: 0.25rem;
          background: oklch(0% 0 0deg / 20%);
          color: var(--text-body);
          font-family: ui-monospace, "SFMono-Regular", monospace;
          font-size: 0.64rem;
          line-height: 1.65;
          overflow-x: auto;
          white-space: pre;
        }

        .pc__notes {
          margin-top: 0.75rem;
          padding: 0.5rem 0.75rem;
          border-left: 2px solid var(--text-deemphasized);
          color: var(--text-deemphasized);
          font-size: 0.68rem;
          line-height: 1.45;
        }
      </style>

      <header class="pc__header">
        <p class="pc__header-title">Palette Comparison</p>
        <p class="pc__header-desc">
          Same markup, same token names — different mode values. Semantic slots proposed for the full system.
        </p>
      </header>

      <div class="pc__grid">
        <.panel {Map.put(@light, :token_readout, build_token_readout(@light.vars))} />
        <.panel {Map.put(@dark, :token_readout, build_token_readout(@dark.vars, :annotated))} />
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :logo_src, :string, required: true
  attr :has_turbulence, :boolean, required: true
  attr :vars, :list, required: true
  attr :gradient, :string, required: true
  attr :token_readout, :string, required: true
  attr :notes, :string, default: nil

  defp panel(assigns) do
    assigns = assign(assigns, :panel_style, build_panel_style(assigns.vars, assigns.gradient))

    ~H"""
    <section class="pc__panel" style={@panel_style}>
      <div :if={@has_turbulence}>
        <%!-- Highlight cloud --%>
        <svg
          class="pc__turbulence-layer"
          style="mix-blend-mode: screen; opacity: 0.8;"
          aria-hidden="true"
          preserveAspectRatio="none"
        >
          <filter id={"pc-hl-#{@id}"}>
            <feTurbulence
              type="fractalNoise"
              baseFrequency="0.007"
              numOctaves="7"
              seed="24"
              result="noise"
            />
            <feGaussianBlur stdDeviation="10" in="noise" result="soft" />
            <feColorMatrix
              in="soft"
              type="matrix"
              values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0.204 0.686 0.069 0 0"
              result="alpha"
            />
            <feFlood flood-color="var(--surface-highlight)" result="tint" />
            <feComposite in="tint" in2="alpha" operator="in" />
          </filter>
          <rect
            width="100%"
            height="100%"
            fill="var(--surface-highlight)"
            filter={"url(#pc-hl-#{@id})"}
          />
        </svg>
        <%!-- Shadow cloud --%>
        <svg
          class="pc__turbulence-layer"
          style="mix-blend-mode: multiply; opacity: 0.22;"
          aria-hidden="true"
          preserveAspectRatio="none"
        >
          <filter id={"pc-sh-#{@id}"}>
            <feTurbulence
              type="fractalNoise"
              baseFrequency="0.008"
              numOctaves="3"
              seed="31"
              result="noise"
            />
            <feGaussianBlur stdDeviation="16" in="noise" result="soft" />
            <feColorMatrix
              in="soft"
              type="matrix"
              values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0.021 0.072 0.007 0 0"
              result="alpha"
            />
            <feFlood flood-color="var(--surface-shadow)" result="tint" />
            <feComposite in="tint" in2="alpha" operator="in" />
          </filter>
          <rect
            width="100%"
            height="100%"
            fill="var(--surface-shadow)"
            filter={"url(#pc-sh-#{@id})"}
          />
        </svg>
        <%!-- Grain --%>
        <svg
          class="pc__turbulence-layer"
          style="mix-blend-mode: overlay; opacity: 0.32;"
          aria-hidden="true"
          preserveAspectRatio="none"
        >
          <filter id={"pc-tx-#{@id}"}>
            <feTurbulence
              type="fractalNoise"
              baseFrequency="0.5"
              numOctaves="1"
              seed="36"
              result="noise"
            />
            <feColorMatrix
              in="noise"
              type="matrix"
              values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0.217 0.729 0.074 0 0"
              result="alpha"
            />
            <feFlood flood-color="var(--text-body)" result="tint" />
            <feComposite in="tint" in2="alpha" operator="in" />
          </filter>
          <rect
            width="100%"
            height="100%"
            fill="var(--text-body)"
            filter={"url(#pc-tx-#{@id})"}
          />
        </svg>
      </div>

      <div class="pc__content">
        <span class="pc__mode-tag">{@label}</span>

        <img
          src={@logo_src}
          alt="Zane Riley"
          width="545"
          height="168"
          class="pc__logo"
        />

        <div>
          <p class="pc__eyebrow">Product designer · Tokyo</p>
          <h2 class="pc__title">Work that holds its ground</h2>
          <p class="pc__body">
            Strategy, visual design, and code — across Google Search, Maps,
            and a decade of products that people actually use.
          </p>
          <a href="#" class="pc__link">Read the self portrait</a>
        </div>

        <div class="pc__tiles">
          <div class="pc__tile" style="background: var(--surface-primary)">
            <span class="pc__tile-label">Primary</span>
            <strong class="pc__tile-heading">Header</strong>
            <p class="pc__tile-body">Body copy stays readable here.</p>
            <a class="pc__tile-link">Link</a>
          </div>
          <div
            class="pc__tile"
            style="background: color-mix(in oklch, var(--surface-primary) 50%, var(--surface-secondary))"
          >
            <span class="pc__tile-label">Midpoint</span>
            <strong class="pc__tile-heading">Header</strong>
            <p class="pc__tile-body">Body copy stays readable here.</p>
            <a class="pc__tile-link">Link</a>
          </div>
          <div class="pc__tile" style="background: var(--surface-secondary)">
            <span class="pc__tile-label">Secondary</span>
            <strong class="pc__tile-heading">Header</strong>
            <p class="pc__tile-body">Body copy stays readable here.</p>
            <a class="pc__tile-link">Link</a>
          </div>
        </div>

        <details class="pc__tokens">
          <summary>Tokens</summary>
          <pre class="pc__token-block">{@token_readout}</pre>
        </details>

        <p :if={@notes} class="pc__notes">{@notes}</p>
      </div>
    </section>
    """
  end

  defp build_panel_style(vars, gradient) do
    var_string = Enum.map_join(vars, "; ", fn {k, v} -> "#{k}: #{v}" end)
    "#{var_string}; background: #{gradient};"
  end

  @dark_annotations %{
    "--surface-primary" => "← #24150a equiv (Frieren warm dark)",
    "--surface-secondary" => "← pure black",
    "--surface-highlight" => "← dusk-700",
    "--surface-shadow" => "",
    "--text-heading" => "← white-point (neutral-0)",
    "--text-body" => "← dusk-100",
    "--text-link" => "← dusk-400 · TBD",
    "--text-deemphasized" => "← dusk-500"
  }

  defp build_token_readout(vars, :annotated) do
    vars
    |> Enum.map_join("\n", fn {k, v} ->
      annotation = Map.get(@dark_annotations, k, "")
      note = if annotation != "", do: "  #{annotation}", else: ""
      pad = String.duplicate(" ", max(0, 26 - String.length(k)))
      "#{k}:#{pad}#{v};#{note}"
    end)
  end

  defp build_token_readout(vars) do
    vars
    |> Enum.map_join("\n", fn {k, v} ->
      pad = String.duplicate(" ", max(0, 26 - String.length(k)))
      "#{k}:#{pad}#{v};"
    end)
  end
end
