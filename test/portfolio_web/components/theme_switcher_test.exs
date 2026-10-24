defmodule PortfolioWeb.Components.ThemeSwitcherTest do
  use PortfolioWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias PortfolioWeb.Components.ThemeSwitcher

  describe "theme_switcher/1" do
    test "renders one named binary button with decorative artwork" do
      html = render_component(&ThemeSwitcher.theme_switcher/1, %{})
      tree = Floki.parse_fragment!(html)
      assert [_] = Floki.find(tree, "button[type=button][aria-pressed=false]")
      assert Floki.attribute(tree, "button", "aria-label") == ["Dark mode"]
      assert Floki.find(tree, "input") == []
      assert [_] = Floki.find(tree, "svg[aria-hidden=true]")
      assert Floki.attribute(tree, "button", "phx-update") == ["ignore"]
    end

    test "namespaces SVG mask references for different instances" do
      html =
        render_component(&ThemeSwitcher.theme_switcher/1, %{id: "footer-theme"})

      assert html =~ ~s(id="footer-theme-face")
      assert html =~ ~s|mask="url(#footer-theme-face)"|
    end
  end
end
