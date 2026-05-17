defmodule PortfolioWeb.SiteOrigin do
  @moduledoc """
  Builds absolute URLs for this site's configured public origin.

  Use this only when an absolute URL is required, such as signed links or
  share metadata. In-app static assets should stay root-relative through `~p`.
  """

  @doc """
  Prepends the configured endpoint origin to a root-relative path.
  """
  @spec absolute_url(String.t()) :: String.t()
  def absolute_url("/" <> _rest = path) do
    PortfolioWeb.Endpoint.url() <> path
  end
end
