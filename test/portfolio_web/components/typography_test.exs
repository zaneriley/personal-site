defmodule PortfolioWeb.Components.TypographyTest do
  use PortfolioWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias PortfolioWeb.Components.Typography

  defp render_typography(attrs, text) do
    assigns =
      attrs
      |> Map.put_new(:font, nil)
      |> Map.put_new(:locale, nil)
      |> Map.put_new(:size, "md")
      |> Map.put_new(:tag, "p")
      |> Map.put(:text, text)

    rendered_to_string(~H"""
    <Typography.typography tag={@tag} size={@size} font={@font} locale={@locale}>
      {@text}
    </Typography.typography>
    """)
  end

  defp get_optical_style(html_fragment) do
    with {:ok, doc} <- Floki.parse_fragment(html_fragment),
         [span | _] <- Floki.find(doc, "span.optical-adjustment"),
         [style | _] <- Floki.attribute(span, "style") do
      style
    else
      _ -> nil
    end
  end

  defp get_outer_classes(html_fragment, tag) do
    with {:ok, doc} <- Floki.parse_fragment(html_fragment),
         [outer | _] <- Floki.find(doc, tag),
         [classes | _] <- Floki.attribute(outer, "class") do
      classes
    else
      _ -> nil
    end
  end

  describe "typography component rendering behavior" do
    test "renders English defaults with Latin optical trim variables" do
      rendered = render_typography(%{locale: "en"}, "Default English Text")

      assert outer_classes = get_outer_classes(rendered, "p")
      assert outer_classes =~ "text-md"
      assert outer_classes =~ "text-main"
      assert outer_classes =~ "font-gt-flexa"
      assert rendered =~ "Default English Text"

      assert style_attr = get_optical_style(rendered)
      assert style_attr =~ "--_lh: var(--lh-en-md);"
      assert style_attr =~ "--_dt: var(--gt-flexa-trial-vf-distance-top);"
      assert style_attr =~ "--_db: var(--gt-flexa-trial-vf-distance-bottom);"
    end

    test "renders Japanese text with Noto classes and no Latin optical trim variables" do
      rendered =
        render_typography(%{locale: "ja", font: "noto", size: "md"}, "日本語テキスト")

      assert outer_classes = get_outer_classes(rendered, "p")
      assert outer_classes =~ "text-md"
      assert outer_classes =~ "text-main"
      assert outer_classes =~ "font-noto-sans-jp"
      refute outer_classes =~ "bold"
      assert rendered =~ "日本語テキスト"

      assert get_optical_style(rendered) == ""
      refute rendered =~ "--_lh:"
      refute rendered =~ "--cjk-lh"
      refute rendered =~ "--_dt:"
      refute rendered =~ "--_db:"
    end

    test "renders Japanese cheee text with the locale-specific bold mapping" do
      rendered =
        render_typography(%{locale: "ja", font: "cheee", size: "md"}, "日本語テキスト")

      assert outer_classes = get_outer_classes(rendered, "p")
      assert outer_classes =~ "font-noto-sans-jp"
      assert outer_classes =~ "bold"

      style_attr = get_optical_style(rendered) || ""
      refute style_attr =~ "--_lh:"
      refute style_attr =~ "--_dt:"
      refute style_attr =~ "--_db:"
    end
  end
end
