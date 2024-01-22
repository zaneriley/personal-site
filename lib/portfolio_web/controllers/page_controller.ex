defmodule PortfolioWeb.PageController do
  use PortfolioWeb, :controller

  def home(conn, _params) do
    run_mode = if System.get_env("RELEASE_NAME"), do: "release", else: "mix"

    conn
    |> render(:home,
      run_mode: run_mode,
      phoenix_ver: Application.spec(:phoenix, :vsn),
      elixir_ver: System.version()
    )
  end

  # New root action for handling root domain requests
  def root(conn, _params) do
    conn
    |> redirect(to: "/en/") # Redirect to the default language path
    |> halt() # Ensure no further processing is done
  end
end
