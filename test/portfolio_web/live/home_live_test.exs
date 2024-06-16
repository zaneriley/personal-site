defmodule PortfolioWeb.HomeLiveTest do
  use PortfolioWeb.ConnCase
  import Plug.Conn
  require Logger
  import Phoenix.LiveViewTest
  alias PortfolioWeb.Router.Helpers, as: Routes

  setup %{conn: conn} do
    conn = conn
           |> Map.put(:secret_key_base, String.duplicate("a", 64))
           |> init_test_session(%{})
    {:ok, conn: conn}
  end

  test "sets the default locale in mount/3", %{conn: conn} do
    # Fetch the session if it exists, otherwise initialize it
    conn = fetch_session(conn)

    # Set the user_locale in the session
    user_locale = get_session(conn, :user_locale) || Application.get_env(:portfolio, :default_locale)
    conn = put_session(conn, :user_locale, user_locale)

    # Use the updated conn to perform the live navigation
    {:ok, _index_live, html} = live(conn, Routes.home_path(conn, :index, user_locale))
    # Assert that the HTML contains the expected content based on the locale
    assert html =~ "Colophon"
  end
  test "sets /ja/ locale in mount/3", %{conn: conn} do
    # Fetch the session if it exists, otherwise initialize it
    conn = fetch_session(conn)

    # Set the user_locale in the session
    # user_locale = get_session(conn, :user_locale) || Application.get_env(:portfolio, :default_locale)
    user_locale = "ja"

    conn = put_session(conn, :user_locale, user_locale)

    # Use the updated conn to perform the live navigation
    {:ok, _index_live, html} = live(conn, Routes.home_path(conn, :index, user_locale))
    # Assert that the HTML contains the expected content based on the locale
    assert html =~ "東京" # Check for Japanese translation
  end
end
