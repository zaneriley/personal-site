defmodule PortfolioWeb.DevController do
  @moduledoc """
  Dev-only design-system tools (standalone, client-side, no app chrome).
  """
  use PortfolioWeb, :controller

  # step 0 = md (modular-scale base). Mirrors the --fs-* labels.
  @sizes [
    %{label: "4xl", step: 4},
    %{label: "3xl", step: 3},
    %{label: "2xl", step: 2},
    %{label: "1xl", step: 1},
    %{label: "md", step: 0},
    %{label: "1xs", step: -1},
    %{label: "2xs", step: -2}
  ]

  @compare_faces [
    %{
      key: "flexa",
      name: "GT Flexa",
      css: "font-gt-flexa",
      note: "variable — tuned here"
    },
    %{
      key: "cardinal",
      name: "Cardinal",
      css: "font-cardinal-fruit",
      note: "static 400 / 700"
    },
    %{key: "cheee", name: "Cheee", css: "font-cheee", note: "variable"},
    %{
      key: "noto",
      name: "Noto Sans JP",
      css: "font-noto-sans-jp",
      note: "static 480"
    }
  ]

  def weight_calibration(conn, _params) do
    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> render(:weight_calibration, sizes: @sizes, compare_faces: @compare_faces)
  end

  # Token groups for the color page — names only; the page reads their live
  # computed values per theme so it always reflects the real scheme.
  @color_groups [
    %{
      name: "Dusk ramp",
      note: "the backbone neutral — pink→blue hue shift, chroma bulge",
      tokens:
        ~w(--dusk-000 --dusk-100 --dusk-200 --dusk-300 --dusk-400 --dusk-500
                 --dusk-600 --dusk-700 --dusk-800 --dusk-900 --dusk-1000)
    },
    %{
      name: "Text ladder",
      note: "semantic, per-mode — what <.typography color=…> resolves to",
      tokens:
        ~w(--text-color-callout --text-color-main --text-color-deemphasized
                 --text-color-suppressed --text-color-accent)
    },
    %{
      name: "Brand / link",
      note:
        "the contested ones — note --accent (blue) vs text-color-accent (gold)",
      tokens: ~w(--accent --hanko-color)
    },
    %{
      name: "Neutral ramp",
      note:
        "cool blue-grey UI/metadata greys (footer chrome, code line numbers)",
      tokens: ~w(--neutral-25 --neutral-50)
    },
    %{
      name: "Gold / points",
      note: "the one gold + the crushed white/black points",
      tokens: ~w(--ochre-0 --white-point --black-point)
    },
    %{
      name: "Signature",
      note: "hand-graded wordmark gradient — its own thing",
      tokens:
        ~w(--signature-1 --signature-2 --signature-3 --signature-4 --signature-kana)
    }
  ]

  def color_tokens(conn, _params) do
    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> render(:color_tokens, color_groups: @color_groups)
  end

  @code_block_sample ~S'''
  <span class="tok-keyword">defmodule</span> <span class="tok-module">PushSearch.Accounts</span> <span class="tok-operator">do</span>
  &nbsp;&nbsp;<span class="tok-string">@behaviour PushSearch.Accounts.Interface</span>

  &nbsp;&nbsp;<span class="tok-string">@moduledoc """</span>
  &nbsp;&nbsp;<span class="tok-string">The Accounts context module (Service Layer).</span>

  &nbsp;&nbsp;<span class="tok-string">This module serves as the boundary and</span>
  &nbsp;&nbsp;<span class="tok-string">primary public API for all account-related</span>
  &nbsp;&nbsp;<span class="tok-string">operations within the application. It orchestrates</span>
  &nbsp;&nbsp;<span class="tok-string">user management tasks by coordinating with the</span>
  &nbsp;&nbsp;<span class="tok-string">domain layer (for entities and validation) and adapters</span>
  &nbsp;&nbsp;<span class="tok-string">(for external interactions like OAuth).</span>
  &nbsp;&nbsp;<span class="tok-string">"""</span>

  &nbsp;&nbsp;<span class="tok-attribute">@</span>impl <span class="tok-type">PushSearch.Accounts.Interface</span>
  &nbsp;&nbsp;<span class="tok-keyword">def</span> <span class="tok-function">find_or_create_user_from_oauth</span><span class="tok-punctuation">(</span>auth_struct<span class="tok-punctuation">)</span> <span class="tok-operator">do</span>
  &nbsp;&nbsp;&nbsp;&nbsp;<span class="tok-keyword">with</span> <span class="tok-call">normalized_attrs</span> <span class="tok-keyword">when</span> <span class="tok-call">is_map</span><span class="tok-punctuation">(</span>normalized_attrs<span class="tok-punctuation">)</span> <span class="tok-operator">←</span>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="tok-module">OauthHandler</span><span class="tok-operator">.normalize_google_auth</span><span class="tok-punctuation">(</span>auth_struct<span class="tok-operator">),</span>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="tok-operator">&#123;</span><span class="tok-atom">:ok</span><span class="tok-operator">,</span> google_id<span class="tok-operator">&#125; ← Map.fetch</span><span class="tok-punctuation">(</span>normalized_attrs<span class="tok-operator">,</span> <span class="tok-atom">:google_id</span><span class="tok-punctuation">)</span> <span class="tok-operator">do</span>
  '''
  @code_block_sample String.replace(@code_block_sample, ~r/^ +/m, "")

  # In-situ code-block harness: the REAL CodeBlock component on the real
  # surface, light + dark, with an OKLCH tweaks panel that overrides the
  # shipped --code-* values inline for retuning. The sample is hand-classified
  # (mock-fidelity) until the pipeline tokenizer lands.
  def code_block(conn, _params) do
    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> render(:code_block, code_sample: @code_block_sample)
  end
end
