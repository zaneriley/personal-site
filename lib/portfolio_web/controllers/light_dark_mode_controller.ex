defmodule PortfolioWeb.LightDarkModeController do
  use PortfolioWeb, :controller

  def toggle(conn, _params) do
    current_theme = GenServer.call(LightDarkMode.GenServer, :get_theme)
    GenServer.cast(LightDarkMode.GenServer, {:toggle, current_theme})
    updated_theme = GenServer.call(LightDarkMode.GenServer, :get_theme)

    json(conn, %{theme: Atom.to_string(updated_theme)})
  end
end
