defmodule PortfolioWeb.RouterTest do
  use PortfolioWeb.ConnCase

  describe "Locale Handling Tests" do
    test "redirects to default locale when no locale is specified", %{
      conn: conn
    } do
      conn = get(conn, "/")
      assert redirected_to(conn, 301) =~ "/en"
    end

    test "accepts valid locale", %{conn: conn} do
      conn = get(conn, "/ja")
      refute conn.halted
    end

    test "returns 404 for invalid locale", %{conn: conn} do
      conn = get(conn, "/invalid-locale")
      assert conn.status == 404
    end
  end

  describe "Error Handling Tests" do
    test "returns 404 for non-existent routes", %{conn: conn} do
      conn = get(conn, "/non-existent-route")
      html = html_response(conn, 404)

      assert html =~ "ERROR 404"
      assert html =~ "DATA NOT FOUND"
      refute html =~ "localhost"
    end
  end
end
