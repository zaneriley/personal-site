defmodule PortfolioWeb.NavigationTest do
  use PortfolioWeb.ConnCase
  import Phoenix.LiveViewTest

  defp destinations(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find(".site-navigation-destinations a")
    |> Enum.map(fn link ->
      {link |> Floki.attribute("href") |> List.first(),
       link |> Floki.text() |> String.trim()}
    end)
  end

  test "English navigation points at work, notes, and about", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/en/work")

    assert destinations(html) == [
             {"/en/work", "Work"},
             {"/en/notes", "Notes"},
             {"/en/about", "About"}
           ]

    assert [_] =
             html
             |> Floki.parse_document!()
             |> Floki.find(~s(a[href="/en/work"][aria-current="page"]))
  end

  test "Japanese navigation keeps English paths with Japanese labels", %{
    conn: conn
  } do
    {:ok, _view, html} = live(conn, ~p"/ja/about")

    assert [{"/ja/work", "実績"}, {"/ja/notes", _}, {"/ja/about", "プロフィール"}] =
             destinations(html)
  end

  test "the old case study, self, and feed paths no longer exist", %{
    conn: conn
  } do
    for path <- [
          "/en/case-studies",
          "/en/case-study/anything",
          "/en/self",
          "/en/feeds/case-studies.xml"
        ] do
      assert conn |> get(path) |> response(404)
    end
  end
end
