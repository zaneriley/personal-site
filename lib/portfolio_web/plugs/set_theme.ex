# lib/portfolio_web/plugs/set_theme.ex
defmodule PortfolioWeb.Plugs.SetTheme do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    theme = get_preferred_theme(conn)
    assign(conn, :theme, theme)
  end

  defp get_preferred_theme(conn) do
    case get_req_header(conn, "prefer-color-scheme") do
      ["dark"] -> "dark"
      _        -> "light"
    end
  end
end
