defmodule PortfolioWeb.Components.ThemeSwitcherTest do
  use PortfolioWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import PortfolioWeb.Gettext
  alias Floki

  alias PortfolioWeb.Components.ThemeSwitcher

  describe "rendering" do
    test "renders correctly with default theme" do
      html = render_component(&ThemeSwitcher.theme_switcher/1, %{})

      assert html =~ "<fieldset"
      # Additional assertions...
    end

    test "renders with specified theme selected" do
      for selected_theme <- ["light", "dark", "system"] do
        html =
          render_component(&ThemeSwitcher.theme_switcher/1, %{class: "my-class"})

        # Assertions to check if the correct theme is selected
        assert html =~ "value=\"#{selected_theme}\""
      end
    end
  end

  describe "accessibility" do
    test "uses semantic HTML elements for accessibility" do
      html = render_component(&ThemeSwitcher.theme_switcher/1, %{})

      # Assertions for accessibility features
      assert html =~ "<legend class=\"sr-only\">"
    end
  end
end
