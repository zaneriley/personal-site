defmodule PortfolioWeb.Components.Identity do
  @moduledoc """
  Zane's own visual-identity marks — the single source of truth for their
  geometry. Each mark is ONE inline SVG that recolors via `currentColor`
  (driven by the page's theme tokens), never a per-theme image pair.

    * `hanko/1` — the personal seal (swirl monogram). Rendered as the nav logo;
      the same geometry is also the favicon (`assets/static/favicon.svg`), which
      adapts via `prefers-color-scheme` because it renders in browser chrome and
      cannot read page tokens.

    * `signature/1` — the calligraphic "Zane Riley" wordmark (the long signature).
      One inline SVG whose gradient stops + kana read `--signature-*` design
      tokens, so a single geometry recolors per theme (dark warm-violet→slate,
      light mint→teal); noise stays in both modes. Lives on the `/` index hero.

  Third-party company logos are a *different* concept (foreign brand colors,
  never themed) and live in `PortfolioWeb.Components.Credits`.
  """
  use Phoenix.Component

  # The signature wordmark is authored + SVGO-optimized as a source file and
  # read at compile time, then injected raw — so the optimized SVG stays the
  # single source of truth (no hand-transcribed copy in the heredoc) and the
  # markup is SSR'd with zero extra requests. @external_resource recompiles the
  # module when the asset changes.
  @signature_path Path.join(__DIR__, "identity/signature.svg")
  @external_resource @signature_path
  @signature_svg File.read!(@signature_path)

  @doc """
  Renders the hanko (personal seal) as an inline SVG.

  The mark owns its appearance: the `.hanko` class fixes its colour
  (`--hanko-color`, the brand accent) and size (one canonical `--space-1xl`
  rung), so every instance is identical by construction. Callers **cannot**
  recolour or resize it — that's a design-system invariant, not a per-call
  choice. `id` only varies the internal clipPath id so multiple instances on
  one page don't collide; `class` is for layout (margins, alignment) only.
  """
  attr :id, :string,
    default: "nav",
    doc:
      "suffix for the internal clipPath id; must be unique per instance on a page"

  attr :class, :string,
    default: nil,
    doc: "extra layout classes (margins, etc.)"

  attr :rest, :global, doc: "aria-* and other passthrough attributes"

  @spec hanko(map()) :: Phoenix.LiveView.Rendered.t()
  def hanko(assigns) do
    ~H"""
    <svg
      viewBox="-3 -3 50 48"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      class={["hanko", @class]}
      {@rest}
    >
      <defs>
        <clipPath id={"hanko-seal-#{@id}"}>
          <rect x="1.9734" y="2.6875" width="39.2886" height="36.625" rx="18.3125" />
        </clipPath>
      </defs>
      <rect
        x="-0.0266113"
        y="0.6875"
        width="43.2886"
        height="40.625"
        rx="20.3125"
        stroke="currentColor"
        stroke-width="4"
      />
      <g clip-path={"url(#hanko-seal-#{@id})"}>
        <path
          fill="currentColor"
          d="M24.095 20.496c.897.19 1.544-.115 1.693-.788.093-.424.248-1.252.402-1.95.236-1.072 3.448-.858 7.036-.093 2.849.607 3.997 1.165 3.843 1.863-.225 1.023-.516 1.587-.691 2.385-.1.449.122 1.2 1.388 1.47 1.108.237 1.656-.116 2.08-1.044.389-.883.576-1.73.757-2.553 1.126-5.112.142-9.42-4.566-13.503a3.55 3.55 0 0 0-1.4-.664c-.607-.13-1.305-.095-1.814.083-6.144 1.562-8.775 5.856-9.764 10.344-.214.973-.37 1.931-.412 2.497-.115 1.15.366 1.722 1.448 1.953m3.919-6.63c-.396-.085-.621-.316-.544-.665.318-1.446 2.399-3.117 5.18-3.96a2.3 2.3 0 0 1 1.201-.057c.37.079.69.252.922.458 1.68 1.402 3.274 3.439 2.9 5.134-.065.3-.183.457-.684.35-.527-.112-1.36-.342-2.97-.685-3.14-.67-5.293-.424-6.005-.575"
        />
        <path
          fill="currentColor"
          d="M11.64 19.576c2.486.323 5.045.706 6.897.715 1.337-.006 1.971-.594 2.172-1.908.157-1.035-.364-2.082-2.048-2.3-1.898-.247-5.393-.031-8.146-.39-.749-.096-1.039-.34-.985-.694.081-.53 1.068-1.278 4.92-3.483 4.33-2.478 7.609-3.958 7.867-5.65.162-1.062-.27-1.633-1.464-1.84-1.646-.291-4.422-.677-7.042-1.018a80 80 0 0 0-4.697-.48c-1.699-.118-2.425.354-2.626 1.668-.173 1.137.235 2.04 1.839 2.248 2.325.302 4.567-.102 6.946.207.669.086.878.32.832.623-.08.53-.856.79-4.789 2.985-4.678 2.613-7.338 4.148-7.67 6.32-.172 1.137.228 1.73 2 2.09 1.534.302 3.75.615 5.994.907"
        />
        <path
          fill="currentColor"
          d="M2.67 37.233c1.45.143 2.043-.517 2.177-1.658.128-1.09-.503-3.82.044-8.488.157-1.344.5-1.49.822-1.458.161.016.454.07.62.267 2.65 2.647 4.03 6.17 6.46 10.462 1.005 1.844 2.076 2.206 3.472 2.343 1.342.133 2.275-.417 2.69-1.633.532-1.538.868-3.942 1.148-6.326.294-2.511.56-5.256.486-6.7-.087-1.573-.994-1.945-1.987-2.043-1.155-.114-2.022.34-2.186 1.735-.116.989.813 4.415.172 9.894-.048.406-.185.649-.56.612-.296-.03-.502-.127-.657-.424-2.636-4.852-5.644-9.767-7.53-11.748-.844-.905-1.351-1.211-2.613-1.335-.832-.082-1.694.09-2.34.975-.653.936-1.451 4.039-1.855 7.488-.23 1.953-.515 3.926-.41 5.809.088 1.343.598 2.086 2.048 2.228"
        />
        <path
          fill="currentColor"
          d="M29.237 39.545c2.04.675 4.155 1.453 6.043 1.998 1.195.333 1.976-.202 2.381-1.254.318-.823.101-1.751-1.067-2.153-2.31-.793-5.417-1.161-9.605-2.6-1.727-.593-1.953-.826-1.344-2.403.643-1.67 1.268-1.947 2.486-1.528 2.295.788 3.862 1.535 4.522 1.762.889.305 1.625-.038 1.934-.838.423-1.097-.243-1.534-2.52-2.263-2.55-.818-1.998-.481-3.216-.9-.736-.253-.903-.491-.71-.994.654-1.692 1.64-2.389 3.164-1.865 4.113 1.412 6.516 2.859 8.014 3.373 1.243.428 2.034-.207 2.387-1.121.318-.823.067-1.738-1.464-2.316-1.336-.562-3.604-1.315-5.787-2.065-1.701-.584-3.326-1.142-4.181-1.384-1.024-.326-2.145-.478-2.966.534-1.783 2.236-3.555 5.563-4.34 7.675-.644 1.67-1.006 2.607-1.281 3.47-.525 1.658.105 2.186 1.51 2.72 1.607.603 3.781 1.376 6.04 2.152"
        />
      </g>
    </svg>
    """
  end

  @doc """
  Renders the calligraphic "Zane Riley" signature wordmark as an inline SVG.

  The gradient stops and kana fill read the per-theme `--signature-*` tokens
  (defined in `assets/css/_color.css`), so one geometry recolors with the page
  theme — no per-mode image pair, no extra request. The wrapper is a block so
  the SVG (`width:100%`) scales to its container; constrain via the caller
  (e.g. a `max-width` on the wrapper or its parent column).
  """
  attr :class, :string,
    default: nil,
    doc: "extra classes merged onto the wrapper"

  attr :rest, :global,
    doc: "style, aria-*, and other passthrough on the wrapper"

  @spec signature(map()) :: Phoenix.LiveView.Rendered.t()
  def signature(assigns) do
    assigns = assign(assigns, :markup, {:safe, @signature_svg})

    ~H"""
    <span class={["signature", @class]} role="img" aria-label="Zane Riley" {@rest}>
      {@markup}
    </span>
    """
  end
end
