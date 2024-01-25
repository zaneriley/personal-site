defmodule PortfolioWeb.Plugs.SetLocaleTest do
  use PortfolioWeb.ConnCase

  alias PortfolioWeb.Plugs.SetLocale
  import Plug.Conn

  @tag :set_locale
  test "redirects to default locale when no locale is in the URL", %{conn: conn} do
    # Arrange: Set up the conn to mimic a request without a locale in the URL
    conn = %{conn | request_path: "/"}

    # Act: Call your SetLocale plug with this conn
    conn = SetLocale.call(conn, %{})

    # Assert: Check that the conn was redirected as expected
    assert conn.status == 302
    assert conn.resp_headers["location"] == "/en/"
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
