defmodule PortfolioWeb.Plugs.CSPHeader.Dev do
  @moduledoc """
  Development environment specific CSP functions.
  """

  @spec frame_src() :: String.t()
  def frame_src, do: "'self'"

  @spec maybe_add_upgrade_insecure_requests(keyword()) :: keyword()
  def maybe_add_upgrade_insecure_requests(directives), do: directives
end
