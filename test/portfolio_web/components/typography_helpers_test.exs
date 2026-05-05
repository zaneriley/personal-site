defmodule PortfolioWeb.Components.TypographyHelpersTest do
  # Use ConnCase for potential environment stability, even if overkill
  # ConnCase provides helpers, _conn often unused here
  use PortfolioWeb.ConnCase, async: true

  alias PortfolioWeb.Components.TypographyHelpers

  describe "get_optical_variable_names/1 (or equivalent helper)" do
    test "returns correct variable names for default font/size in 'en' locale" do
      # size defaults to "md", font defaults to "flexa" for "en"
      assigns = %{locale: "en"}

      expected = %{
        lh_var: "--lh-en-md",
        dt_var: "--gt-flexa-trial-vf-distance-top",
        db_var: "--gt-flexa-trial-vf-distance-bottom"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected
    end

    test "returns correct variable names for specific font/size in 'en' locale" do
      assigns = %{font: "cheee", size: "2xl", locale: "en"}

      expected = %{
        lh_var: "--lh-en-2xl",
        dt_var: "--cheee-small-distance-top",
        db_var: "--cheee-small-distance-bottom"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected

      assigns = %{font: "cardinal", size: "1xs", locale: "en"}

      expected = %{
        lh_var: "--lh-en-1xs",
        dt_var: "--cardinal-fruit-web-medium-trial-distance-top",
        db_var: "--cardinal-fruit-web-medium-trial-distance-bottom"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected
    end

    test "returns nil/empty map for 'ja' locale (optical correction disabled)" do
      assigns = %{font: "cheee", size: "md", locale: "ja"}
      assert TypographyHelpers.generate_optical_style(assigns) in [nil, %{}]

      # Font maps to noto-sans-jp metric key
      assigns = %{font: "noto", size: "md", locale: "ja"}
      # Still disabled for 'ja'
      assert TypographyHelpers.generate_optical_style(assigns) in [nil, %{}]
    end

    test "returns nil/empty map for unknown font in 'en' locale" do
      assigns = %{font: "unknown-font", size: "md", locale: "en"}
      assert TypographyHelpers.generate_optical_style(assigns) in [nil, %{}]
    end

    test "handles assigns map missing optional keys" do
      # Missing :font, defaults to flexa for 'en'
      assigns = %{size: "1xl", locale: "en"}

      expected = %{
        lh_var: "--lh-en-1xl",
        dt_var: "--gt-flexa-trial-vf-distance-top",
        db_var: "--gt-flexa-trial-vf-distance-bottom"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected

      # Missing :size, defaults to md
      assigns = %{font: "cheee", locale: "en"}

      expected = %{
        lh_var: "--lh-en-md",
        dt_var: "--cheee-small-distance-top",
        db_var: "--cheee-small-distance-bottom"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected

      # Missing :locale, defaults based on Gettext (assume "en" for test)
      assigns = %{font: "cheee", size: "md"}

      expected = %{
        lh_var: "--lh-en-md",
        dt_var: "--cheee-small-distance-top",
        db_var: "--cheee-small-distance-bottom"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected
    end
  end

  # Optional tests for internal helpers can remain commented or removed
  # if the main describe block provides sufficient coverage.
  # describe "internal helpers (optional tests)" do
  #   defp get_metric_key(logical_font_key) do
  #     Map.get(TypographyHelpers.__info__(:attributes)[:logical_to_metric_key], logical_font_key)
  #   end
  #
  #   test "get_metric_key/1 returns correct key" do
  #     assert get_metric_key("cardinal") == "cardinal-fruit-web-medium-trial"
  #     assert get_metric_key("cheee") == "cheee-small"
  #     assert get_metric_key("flexa") == "gt-flexa-trial-vf"
  #     assert get_metric_key("noto") == "noto-sans-jp"
  #     assert get_metric_key("unknown") == nil
  #   end
  # end
end
