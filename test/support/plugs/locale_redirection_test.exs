defmodule PortfolioWeb.LocaleRedirectionTest do
  use PortfolioWeb.ConnCase
  import Plug.Conn

  @supported_locales ["en", "ja"]
  @default_locale "en"

  setup do
    %{conn: build_conn()}
  end

  describe "LocaleRedirection plug" do
    test "proceeds with request when supported locale is in URL", %{conn: conn} do
      for locale <- @supported_locales do
        conn = get(conn, "/#{locale}/")
        assert_request_proceeded(conn)
      end
    end

    test "proceeds with request when supported locale is in URL (case-insensitive)",
         %{conn: conn} do
      for locale <- @supported_locales do
        conn = get(conn, "/#{String.upcase(locale)}")
        assert_request_proceeded(conn)
      end
    end

    test "redirects to default locale when no locale is in URL", %{conn: conn} do
      conn = get(conn, "/")
      assert_redirected_to(conn, "/#{@default_locale}")
    end

    test "redirects to user's preferred locale when no locale is in URL", %{
      conn: conn
    } do
      preferred_locale = "ja"

      conn =
        conn
        |> init_test_session(%{})
        |> put_session("user_locale", preferred_locale)
        |> get("/")

      assert_redirected_to(conn, "/#{preferred_locale}")
    end

    test "preserves path segments during redirection", %{conn: conn} do
      paths = [
        "notes"
      ]

      for path <- paths do
        conn =
          conn
          |> init_test_session(%{})
          |> put_session("user_locale", "ja")
          |> get("/#{path}")

        assert_redirected_to(conn, "/ja/#{path}")
      end
    end

    test "ignores empty path segments and processes request", %{conn: conn} do
      conn = get(conn, "//en/")
      assert_request_proceeded(conn)
    end

    test "redirects unsupported locale to default locale", %{conn: conn} do
      conn = get(conn, "/xyz/case-study/helping-people-find-healthcare")

      assert_redirected_to(
        conn,
        "/#{@default_locale}/case-study/helping-people-find-healthcare"
      )
    end

    test "returns 404 for invalid routes", %{conn: conn} do
      invalid_paths = [
        "/en/invalid-path"
      ]

      for path <- invalid_paths do
        conn = get(conn, path)
        assert conn.status == 404
      end
    end

    test "returns 404 for unsupported locale in URL", %{conn: conn} do
      conn = get(conn, "/xyz/")
      assert conn.status == 404
    end
  end

  # Helper functions
  defp assert_request_proceeded(conn) do
    assert conn.status != 404
    assert conn.halted == false
  end

  defp assert_redirected_to(conn, expected_path) do
    assert redirected_to(conn, 301) == expected_path
  end
end
