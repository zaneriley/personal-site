defmodule PortfolioWeb.DarkBackgroundSketchLiveTest do
  use PortfolioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the composer with seeded gradient", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/en/dark-background-sketch")
    assert html =~ "big-name-dark.svg"
    assert html =~ "Gradient 1"
    assert html =~ "radial-gradient"
  end

  test "updating a stop color repaints the background", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/en/dark-background-sketch")

    html =
      view
      |> form("form", sketch: %{"g1_s1_color" => "#112233"})
      |> render_change()

    assert html =~ "#112233"
  end
end
