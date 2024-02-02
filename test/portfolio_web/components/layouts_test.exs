defmodule PortfolioWeb.LayoutsTest do
  use PortfolioWeb.ConnCase, async: true
  import Phoenix.ConnTest

  @supported_locales Application.compile_env(:portfolio, :supported_locales)

  setup do
    conn = build_conn()
    |> put_private(:plug_session, %{})
    |> fetch_session(%{})
    {:ok, conn: conn}
  end

  defp test_hreflang_tags_for_locale(conn, locale) do
    conn = put_req_header(conn, "accept-language", locale)
    hreflang_tags = PortfolioWeb.Layouts.hreflang_tags(conn)

    for locale <- @supported_locales do
      assert hreflang_tags =~ ~s(hreflang="#{locale}")
    end
  end

  test "hreflang_tags generates correct tags for en locale", %{conn: conn} do
    test_hreflang_tags_for_locale(conn, "en")
  end

  test "hreflang_tags generates correct tags for ja locale", %{conn: conn} do
    test_hreflang_tags_for_locale(conn, "ja")
  end

  # Add more test cases for other supported locales...
end
