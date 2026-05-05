defmodule PortfolioWeb.Components.TypographyTest do
  use PortfolioWeb.ConnCase, async: true

  # Import necessary modules
  import Phoenix.LiveViewTest
  import Floki

  # Alias the component under test
  alias PortfolioWeb.Components.Typography

  # Helper to easily extract the style attribute content
  defp get_optical_style(html_fragment) do
    with {:ok, doc} <- Floki.parse_fragment(html_fragment),
         [span | _] <- Floki.find(doc, "span.optical-adjustment"),
         [style | _] <- Floki.attribute(span, "style") do
      style
    else
      # Return nil if span or style attribute is not found
      _ -> nil
    end
  end

  # Helper to extract outer tag classes
  defp get_outer_classes(html_fragment, tag \\ "p") do
    with {:ok, doc} <- Floki.parse_fragment(html_fragment),
         [outer | _] <- Floki.find(doc, tag),
         [classes | _] <- Floki.attribute(outer, "class") do
      classes
    else
      _ -> nil
    end
  end

  describe "typography component rendering behavior" do
    test "renders defaults and applies full optical style for 'en' locale", %{
      conn: _conn
    } do
      # Uses default font 'flexa' for en
      assigns = %{locale: "en"}

      rendered =
        render_component(&Typography.typography/1, assigns) do
          "Default English Text"
        end

      assert outer_classes = get_outer_classes(rendered, "p")

      assert outer_classes =~ "text-md" && outer_classes =~ "text-main" &&
               outer_classes =~ "font-gt-flexa"

      assert style_attr = get_optical_style(rendered)
      assert style_attr =~ "--_lh: var(--lh-en-md);"
      assert style_attr =~ "--_dt: var(--gt-flexa-trial-vf-distance-top);"
      assert style_attr =~ "--_db: var(--gt-flexa-trial-vf-distance-bottom);"
    end

    test "applies only CJK line height for 'ja' locale", %{conn: _conn} do
      # Use a known CJK font
      assigns = %{locale: "ja", font: "noto", size: "md"}

      rendered =
        render_component(&Typography.typography/1, assigns) do
          "日本語テキスト"
        end

      # Verify outer tag and classes (Japanese font mapping)
      assert outer_classes = get_outer_classes(rendered, "p")
      assert outer_classes =~ "text-md"
      # Default font for 'ja'
      assert outer_classes =~ "font-noto-sans-jp"
      # The helper also adds bold for this specific combo in font_variants
      assert outer_classes =~ "bold"

      # Verify optical style attribute content
      assert style_attr = get_optical_style(rendered)
      # Assert ONLY --_lh is set, and it points to --cjk-lh
      assert style_attr == "--_lh: var(--cjk-lh);"
      # Explicitly check that dt/db are NOT present
      refute style_attr =~ "--_dt:"
      refute style_attr =~ "--_db:"
    end

    # Add other existing tests back here if needed
  end
end
