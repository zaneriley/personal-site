defmodule PortfolioWeb.Plugs.SetTheme do
  @moduledoc """
    A plug that sets the theme for the connection based on the client's preference.

    The plug checks the 'Prefer-Color-Scheme' HTTP request header to determine if the user has a preferred theme (e.g., 'dark' or 'light'). The determined theme is then assigned to the connection, allowing the application to render the appropriate theme for the user.

    If the header is not present or does not indicate a preference, the plug falls back to a default theme, typically 'light'.
  """
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    theme = get_preferred_theme(conn)
    assign(conn, :theme, theme)
  end

  defp get_preferred_theme(conn) do
    case get_req_header(conn, "prefer-color-scheme") do
      ["dark"] -> "dark"
      _ -> "light"
    end
  end
end
