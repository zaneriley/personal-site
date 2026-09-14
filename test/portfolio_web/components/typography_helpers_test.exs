defmodule PortfolioWeb.Components.TypographyHelpersTest do
  # Use ConnCase for potential environment stability, even if overkill
  # ConnCase provides helpers, _conn often unused here
  use PortfolioWeb.ConnCase, async: true

  alias PortfolioWeb.Components.TypographyHelpers

  describe "generate_optical_style/1" do
    test "returns correct variable names for default font/size in 'en' locale" do
      # size defaults to "md", font defaults to "flexa" for "en"
      assigns = %{locale: "en"}

      expected = %{
        cap_var: "--gt-flexa-trial-vf-cap",
        trim_start_var: "--gt-flexa-trial-vf-trim-start",
        trim_end_var: "--gt-flexa-trial-vf-trim-end"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected
    end

    test "returns correct variable names for specific font/size in 'en' locale" do
      assigns = %{font: "cheee", size: "2xl", locale: "en"}

      expected = %{
        cap_var: "--cheee-small-cap",
        trim_start_var: "--cheee-small-trim-start",
        trim_end_var: "--cheee-small-trim-end"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected

      assigns = %{font: "cardinal", size: "1xs", locale: "en"}

      expected = %{
        cap_var: "--cardinal-fruit-web-medium-trial-cap",
        trim_start_var: "--cardinal-fruit-web-medium-trial-trim-start",
        trim_end_var: "--cardinal-fruit-web-medium-trial-trim-end"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected
    end

    test "uses shared body trim rather than face metrics for 'ja'" do
      assigns = %{font: "cheee", size: "md", locale: "ja"}
      assert TypographyHelpers.generate_optical_style(assigns) in [nil, %{}]

      # Font maps to noto-sans-jp metric key
      assigns = %{font: "noto", size: "md", locale: "ja"}
      # CJK correction lives in the shared CSS rule
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
        cap_var: "--gt-flexa-trial-vf-cap",
        trim_start_var: "--gt-flexa-trial-vf-trim-start",
        trim_end_var: "--gt-flexa-trial-vf-trim-end"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected

      # Missing :size, defaults to md
      assigns = %{font: "cheee", locale: "en"}

      expected = %{
        cap_var: "--cheee-small-cap",
        trim_start_var: "--cheee-small-trim-start",
        trim_end_var: "--cheee-small-trim-end"
      }

      assert TypographyHelpers.generate_optical_style(assigns) == expected

      # Missing :locale, defaults based on Gettext (assume "en" for test)
      assigns = %{font: "cheee", size: "md"}

      expected = %{
        cap_var: "--cheee-small-cap",
        trim_start_var: "--cheee-small-trim-start",
        trim_end_var: "--cheee-small-trim-end"
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
