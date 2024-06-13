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

  test "sets the correct locale in mount/3", %{conn: conn} do
    user_locale = session["user_locale"] || Application.get_env(:portfolio, :default_locale)
    conn = conn
           |> fetch_session()
           |> put_session(:user_locale, user_locale)
    Logger.error(@socket, "User locale: #{user_locale}")
    {:ok, _index_live, html} = live(conn, Routes.home_path(@socket, :index, @user_locale))
    assert html =~ "分" # Check for Japanese translation
  end
end
