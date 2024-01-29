defmodule PortfolioWeb.Plugs.SetLocaleTest do
  use PortfolioWeb.ConnCase

  alias PortfolioWeb.Plugs.SetLocale
  import Plug.Conn

  @tag :set_locale
  test "redirects to the preferred language when no locale is in the URL", %{conn: conn} do
    # Arrange: Set up the conn to mimic a request without a locale in the URL
    conn = put_req_header(conn, "accept-language", "ja")

    # Act: Call your SetLocale plug with this conn
    conn = SetLocale.call(conn, %{})

    # Assert: Check that the conn was redirected as expected
    assert conn.status == 302
    assert conn.resp_headers["location"] == "/ja/"
  end

  @tag :set_locale
  test "redirects to the preferred language when visiting a specific path", %{conn: conn} do
    # Arrange: Set up the conn to mimic a request to a specific path without a locale in the URL
    conn = put_req_header(conn, "accept-language", "ja")
    conn = put_path(conn, "/case-study/my-cool-case-study")

    # Act: Call your SetLocale plug with this conn
    conn = SetLocale.call(conn, %{})

    # Assert: Check that the conn was redirected as expected
    assert conn.status == 302
    assert conn.resp_headers["location"] == "/ja/case-study/my-cool-case-study"
  end

  @tag :set_locale
  test "does not redirect when visiting a static file", %{conn: conn} do
    # Arrange: Set up the conn to mimic a request to a static file without a locale in the URL
    conn = put_req_header(conn, "accept-language", "ja")
    conn = put_path(conn, "/favicon-32x32.png")

    # Act: Call your SetLocale plug with this conn
    conn = SetLocale.call(conn, %{})

    # Assert: Check that the conn was not redirected
    assert conn.status != 302
  end

  # @tag :set_locale
  # test "does not redirect when a supported locale is in the URL", %{conn: conn} do
  #   # Arrange, Act, and Assert for this scenario
  # end

  # @tag :set_locale
  # test "redirects to default locale when an unsupported locale is in the URL", %{conn: conn} do
  #   # Arrange, Act, and Assert for this scenario
  # end

  # @tag :set_locale
  # test "redirects based on accept-language when no locale is in the URL", %{conn: conn} do
  #   # Arrange, Act, and Assert for this scenario
  # end

end
