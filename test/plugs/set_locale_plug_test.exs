defmodule PortfolioWeb.SetLocalePlugTest do
  use PortfolioWeb.ConnCase

  import Plug.Conn

  alias PortfolioWeb.I18nHelpers

  describe "SetLocale plug" do
    test "sets the locale based on the Accept-Language header", %{conn: conn} do
      conn = I18nHelpers.set_accept_language_header(conn, "ja")
      conn = get(conn, "/")
      assert get_session(conn, "user_locale") == "ja"
      assert conn.resp_headers |> Enum.any?(fn {key, value} -> key == "content-language" and value == "ja" end)
    end

    test "sets the locale based on the URL path segment", %{conn: conn} do
      conn = get(conn, "/en/")
      assert get_session(conn, "user_locale") == "en"
    end

    test "prioritizes the session locale over the URL path segment and Accept-Language header", %{conn: conn} do
      conn = conn
      |> fetch_session()
      |> put_session("user_locale", "ja")
      |> I18nHelpers.set_accept_language_header("en")
      |> get("/en")

      assert get_session(conn, "user_locale") == "ja"
    end

    test "sets the locale based on the Accept-Language header when no session or URL locale is set", %{conn: conn} do
      conn = I18nHelpers.set_accept_language_header(conn, "ja")
      conn = get(conn, "/")
      assert get_session(conn, "user_locale") == "ja"
    end

    test "falls back to the default locale if no locale is specified", %{conn: conn} do
      conn = get(conn, "/")
      assert get_session(conn, "user_locale") == "en" # Assuming "en" is the default locale
    end

    test "sets the default locale for unsupported locales", %{conn: conn} do
      conn = I18nHelpers.set_accept_language_header(conn, "unsupported_locale")
      conn = get(conn, "/unsupported_locale/")
      assert get_session(conn, "user_locale") == "en" # Assuming "en" is the default locale
    end

    test "does not set locale for static asset requests", %{conn: conn} do
      conn = get(conn, "/images/logo.png")
      refute conn.assigns[:user_locale]
    end

    test "sets the Content-Language response header correctly", %{conn: conn} do
      conn = I18nHelpers.set_accept_language_header(conn, "ja")
      conn = get(conn, "/")
      assert conn.resp_headers |> Enum.any?(fn {key, value} -> key == "content-language" and value == "ja" end)
    end
  end
end
