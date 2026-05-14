defmodule PortfolioWeb.Plugs.CSPHeader.Dev do
  @moduledoc """
  Development environment specific CSP functions.
  """

  @spec frame_src() :: String.t()
  def frame_src, do: "'self'"
end
