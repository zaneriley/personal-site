defmodule PortfolioWeb.Plugs.CSPHeader.Prod do
  @moduledoc """
  Production environment specific CSP functions.
  """

  @spec frame_src() :: String.t()
  def frame_src, do: "'none'"

  @spec maybe_add_upgrade_insecure_requests(keyword()) :: keyword()
  def maybe_add_upgrade_insecure_requests(directives) do
    [{"upgrade-insecure-requests", ""} | directives]
  end
end
