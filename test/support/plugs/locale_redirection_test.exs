defmodule PortfolioWeb.LocaleRedirectionTest do
  use PortfolioWeb.ConnCase
  import Plug.Conn

  describe "LocaleRedirection plug" do
    test "allows request to proceed with supported locale in URL", %{conn: conn} do
      conn = get(conn, "/en/")
      # assert conn.status != 404
      assert conn.halted == false
    end

    test "responds with 404 for unsupported locale in URL", %{conn: conn} do
      conn = get(conn, "/xyz/")
      assert conn.status == 404
    end

    test "redirects to user's preferred locale when no locale in URL" do
      conn =
        session_conn()
        |> put_session("user_locale", "ja")
        |> get("/")

      assert redirected_to(conn) == "/ja/"
    end

    test "redirects to default locale when no locale in URL and no user preference",
         %{conn: conn} do
      conn = get(conn, "/")
      assert redirected_to(conn) == "/en/"
    end

    @tag :skip
    test "ignores empty path segments and processes request", %{conn: conn} do
      conn = get(conn, "//en/")
      assert conn.status != 404
      assert conn.halted == false
    end

    @tag :skip
    test "does not respond with 404 for unsupported locale as non-first segment",
         %{conn: conn} do
      conn = get(conn, "/case-study/helping-people-find-healthcare")
      assert conn.status != 404
    end

    @tag :skip
    test "handles supported locale case sensitivity", %{conn: conn} do
      conn = get(conn, "/EN/")
      assert conn.status != 404
      assert conn.halted == false
    end
  end
end
