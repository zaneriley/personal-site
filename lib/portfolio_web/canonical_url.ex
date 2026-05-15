defmodule PortfolioWeb.CanonicalUrl do
  @moduledoc """
  Returns the canonical URL for a path, or `nil` when this instance is not the
  canonical production origin.

  `:canonical_origin` is set in `runtime.exs` only when `PHX_HOST ==
  "zaneriley.com"`. Preview, dev, and any other host get `nil` so the layout
  emits no `<link rel="canonical">`. Each locale segment is preserved in the
  canonical URL (`/en/note/foo` and `/ja/note/foo` are distinct canonicals,
  paired by `hreflang`).
  """

  @spec for_path(String.t()) :: String.t() | nil
  def for_path("/" <> _rest = path) do
    case Application.get_env(:portfolio, :canonical_origin) do
      nil -> nil
      origin when is_binary(origin) -> origin <> path
    end
  end
end
