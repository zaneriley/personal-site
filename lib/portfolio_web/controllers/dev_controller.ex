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
    %{key: "flexa", name: "GT Flexa", css: "font-gt-flexa", note: "variable — tuned here"},
    %{key: "cardinal", name: "Cardinal", css: "font-cardinal-fruit", note: "static 400 / 700"},
    %{key: "cheee", name: "Cheee", css: "font-cheee", note: "variable"},
    %{key: "noto", name: "Noto Sans JP", css: "font-noto-sans-jp", note: "static 480"}
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
      tokens: ~w(--dusk-000 --dusk-100 --dusk-200 --dusk-300 --dusk-400 --dusk-500
                 --dusk-600 --dusk-700 --dusk-800 --dusk-900 --dusk-1000)
    },
    %{
      name: "Text ladder",
      note: "semantic, per-mode — what <.typography color=…> resolves to",
      tokens: ~w(--text-color-callout --text-color-main --text-color-deemphasized
                 --text-color-suppressed --text-color-accent)
    },
    %{
      name: "Brand / link",
      note: "the contested ones — note --accent (blue) vs text-color-accent (gold)",
      tokens: ~w(--accent --hanko-color)
    },
    %{
      name: "Neutral (legacy)",
      note: "vestigial — mislabeled + mixed formats, mostly unused",
      tokens: ~w(--neutral-0 --neutral-100 --neutral-200 --neutral-300)
    },
    %{
      name: "Gold / points",
      note: "the one gold + the crushed white/black points",
      tokens: ~w(--ochre-0 --white-point --black-point)
    },
    %{
      name: "Signature",
      note: "hand-graded wordmark gradient — its own thing",
      tokens: ~w(--signature-1 --signature-2 --signature-3 --signature-4 --signature-kana)
    }
  ]

  def color_tokens(conn, _params) do
    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> render(:color_tokens, color_groups: @color_groups)
  end
end
