defmodule PortfolioWeb.PaletteComparisonLiveTest do
  use PortfolioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders both panels", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/en/palette-comparison")
    assert html =~ "big-name-light.svg"
    assert html =~ "big-name-dark.svg"
    assert html =~ "--surface-primary"
    assert html =~ "Light"
    assert html =~ "Dark"
  end
end
