defmodule PortfolioWeb.PageControllerTest do
  use PortfolioWeb.ConnCase

  @default_locale Application.compile_env(:portfolio, :default_locale)

  test "home page loads", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == "/en/"
  end

  test "does not set locale for static assets", %{conn: conn} do
    conn = get(conn, "/favicon.ico")
    assert conn.assigns[:user_locale] == nil
  end

  test "sets supported locale from URL without redirection", %{conn: conn} do
    conn = get(conn, "/en/")
    assert conn.assigns[:user_locale] == "en"
  end

  test "sets locale from Accept-Language header when no locale in URL", %{
    conn: conn
  } do
    conn = put_req_header(conn, "accept-language", "ja")
    conn = get(conn, "/")
    assert conn.assigns[:user_locale] == "ja"
  end

  test "sets default locale when no Accept-Language header and no locale in URL",
       %{conn: conn} do
    conn = get(conn, "/")
    assert conn.assigns[:user_locale] == @default_locale
  end
end
