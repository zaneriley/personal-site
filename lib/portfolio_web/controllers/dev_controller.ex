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
end
