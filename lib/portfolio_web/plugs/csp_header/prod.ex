defmodule PortfolioWeb.Plugs.CSPHeader.Prod do
  @moduledoc """
  Production environment specific CSP functions.
  """

  @spec frame_src() :: String.t()
  def frame_src, do: "'none'"
end
