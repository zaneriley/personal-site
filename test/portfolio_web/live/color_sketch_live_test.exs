defmodule PortfolioWeb.ColorSketchLiveTest do
  use PortfolioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "GET /:locale/color-sketch" do
    test "renders separate OKLCH controls for background and text colors", %{
      conn: conn
    } do
      {:ok, _view, html} = live(conn, ~p"/en/color-sketch")

      assert html =~ "Light color sketch"
      assert html =~ "Light field"
      assert html =~ "Blue field"
      assert html =~ "Highlight wash"
      assert html =~ "Shadow wash"
      assert html =~ "Header Text"
      assert html =~ "Body Text"
      assert html =~ "Link Text"
      assert html =~ "Light palette sketch"
      assert html =~ "Surface"
      assert html =~ "Text colors"
      assert html =~ "Light and shadow"
      assert html =~ "Grain"
      assert html =~ "Readability samples"
      assert html =~ "Readability"
      assert html =~ "Surface gradient"
      assert html =~ "Scale"
      assert html =~ "Blend Mode"
      assert html =~ "Contrast"
      assert html =~ "Variation"
      assert html =~ "feTurbulence"
      assert html =~ "baseFrequency"
      assert html =~ "WCAG 2.2"
      assert html =~ "APCA Lc"
      assert html =~ "Worst:"
      assert html =~ "Export candidate"
      assert html =~ "Link fails on blue field."
      assert html =~ "--bg-a: oklch(100% 0.07 247deg)"
      assert html =~ "--bg-b: oklch(84% 0.141 238deg)"
      assert html =~ "--highlight-shape: oklch(100% 0.172 268.8deg)"
      assert html =~ "--shadow-shape: oklch(78.9% 0.104 360deg)"
      assert html =~ ~s(background gradient type=&quot;radial&quot;)
      assert html =~ ~s(background gradient angle=&quot;10&quot;)
      assert html =~ ~s(background gradient midpoint=&quot;53&quot;)
      assert html =~ ~s(background gradient origin=&quot;71% 26%&quot;)
      assert html =~ ~s(background gradient size=&quot;123&quot;)
      assert html =~ ~s(highlight feature size=&quot;109&quot;)
      assert html =~ ~s(highlight feTurbulence baseFrequency=&quot;0.009&quot;)
      assert html =~ ~s(numOctaves=&quot;5&quot;)
      assert html =~ ~s(seed=&quot;7&quot;)
      assert html =~ ~s(highlight blur=&quot;10&quot;)
      assert html =~ ~s(highlight opacity=&quot;0.8&quot;)
      assert html =~ ~s(highlight blend mode=&quot;normal&quot;)
      assert html =~ ~s(highlight contrast=&quot;1.03&quot;)
      assert html =~ ~s(shadow feature size=&quot;14&quot;)
      assert html =~ ~s(shadow feTurbulence baseFrequency=&quot;0.071&quot;)
      assert html =~ ~s(numOctaves=&quot;3&quot;)
      assert html =~ ~s(seed=&quot;31&quot;)
      assert html =~ ~s(shadow blur=&quot;16&quot;)
      assert html =~ ~s(shadow opacity=&quot;0.22&quot;)
      assert html =~ ~s(shadow blend mode=&quot;multiply&quot;)
      assert html =~ ~s(shadow contrast=&quot;0.1&quot;)
      assert html =~ ~s(surface texture size=&quot;2&quot;)
      assert html =~ ~s(texture feTurbulence baseFrequency=&quot;0.5&quot;)
      assert html =~ ~s(texture opacity=&quot;0.2&quot;)
      assert html =~ ~s(texture blend mode=&quot;soft-light&quot;)
      assert html =~ ~s(texture contrast=&quot;1.8&quot;)
      assert html =~ "Header"
      assert html =~ "Body"
      assert html =~ "Link"
      assert html =~ "AAA pass"
      assert html =~ "AA pass"
      assert html =~ "fail"
    end

    test "updates color, shape, and texture values through the sketch form", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/en/color-sketch")

      html =
        view
        |> form("#color-sketch-controls",
          sketch: %{
            "body_text_l" => "45",
            "body_text_c" => "0.05",
            "body_text_h" => "60",
            "gradient_midpoint" => "40",
            "gradient_origin_x" => "25",
            "gradient_origin_y" => "75",
            "gradient_size" => "120",
            "highlight_size" => "25",
            "highlight_blend_mode" => "multiply",
            "highlight_density" => "1.1",
            "highlight_detail" => "6",
            "highlight_shape_l" => "95",
            "highlight_shape_c" => "0.09",
            "highlight_shape_h" => "110",
            "shadow_shape_l" => "48",
            "shadow_shape_c" => "0.1",
            "shadow_shape_h" => "250",
            "shadow_size" => "50",
            "shadow_opacity" => "0.3",
            "shadow_blend_mode" => "multiply",
            "texture_size" => "8",
            "texture_opacity" => "0.14",
            "texture_blend_mode" => "overlay",
            "texture_contrast" => "1.3"
          }
        )
        |> render_change()

      assert html =~ "--body-text: oklch(45% 0.05 60deg)"
      assert html =~ "--highlight-shape: oklch(95% 0.09 110deg)"
      assert html =~ "--shadow-shape: oklch(48% 0.1 250deg)"
      assert html =~ ~s(background gradient type=&quot;radial&quot;)
      assert html =~ ~s(background gradient angle=&quot;10&quot;)
      assert html =~ ~s(background gradient midpoint=&quot;40&quot;)
      assert html =~ ~s(background gradient origin=&quot;25% 75%&quot;)
      assert html =~ ~s(background gradient size=&quot;120&quot;)
      assert html =~ "radial-gradient(circle at 25% 75%"
      assert html =~ ~s(highlight feature size=&quot;25&quot;)
      assert html =~ ~s(baseFrequency="0.04")
      assert html =~ ~s(numOctaves="6")
      assert html =~ "--highlight-blend-mode: multiply"
      assert html =~ ~s(highlight blend mode=&quot;multiply&quot;)
      assert html =~ ~s(highlight contrast=&quot;1.1&quot;)
      assert html =~ "--shadow-opacity: 0.3"
      assert html =~ "--shadow-blend-mode: multiply"
      assert html =~ ~s(shadow feature size=&quot;50&quot;)
      assert html =~ "--texture-opacity: 0.14"
      assert html =~ "--texture-blend-mode: overlay"
      assert html =~ ~s(surface texture size=&quot;8&quot;)
      assert html =~ ~s(texture blend mode=&quot;overlay&quot;)
    end
  end
end
