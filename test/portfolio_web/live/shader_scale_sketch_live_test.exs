defmodule PortfolioWeb.ShaderScaleSketchLiveTest do
  use PortfolioWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "GET /:locale/shader-scale-sketch" do
    test "renders reserved endpoints, grade keyframes, tween ramp, and role controls",
         %{
           conn: conn
         } do
      {:ok, _view, html} = live(conn, ~p"/en/shader-scale-sketch")

      assert html =~ "Color grade system sketch"
      assert html =~ "Role palettes with diagnostic ramps"
      assert html =~ "Absolute white"
      assert html =~ "Absolute black"
      assert html =~ "Current state"
      assert html =~ "Grade keyframes"
      assert html =~ "Light keyframe"
      assert html =~ "Current tween"
      assert html =~ "Dark keyframe"
      assert html =~ "Current tween state"
      assert html =~ "Text on light"
      assert html =~ "Text on dark"
      assert html =~ "The quiet page"
      assert html =~ "Read the self portrait"
      assert html =~ "Metadata, dates, and soft labels."
      assert html =~ "Surface color"
      assert html =~ "Surface C"
      assert html =~ "Surface H"
      assert html =~ "Reading ink"
      assert html =~ "Heading L"
      assert html =~ "Heading C"
      assert html =~ "Heading H"
      assert html =~ "Body L"
      assert html =~ "Body C"
      assert html =~ "Body H"
      assert html =~ "Action ink"
      assert html =~ "Link L"
      assert html =~ "Link C"
      assert html =~ "Link H"
      assert html =~ "Theme mix"
      assert html =~ "Advanced model"
      assert html =~ "white 94 / black 36 / body 40.6 / link 46.5"
      assert html =~ "mode 50% / s-curve"
      assert html =~ "--grade-background: oklch(94% 0.07 247deg)"
      assert html =~ "L1"
      assert html =~ "oklch(94% 0.07 247deg)"
      assert html =~ "C1"
      assert html =~ "oklch(53% 0.049 257.5deg)"
      assert html =~ "D1"
      assert html =~ "oklch(12% 0.028 268deg)"
      assert html =~ "--grade-heading: oklch(32.8% 0.056 48deg)"
      assert html =~ "--grade-body: oklch(40.6% 0.039 54deg)"
      assert html =~ "--grade-link: oklch(46.5% 0.217 252deg)"
      assert html =~ "oklch(36%"
      refute html =~ "HDR"
      refute html =~ "dynamic-range"
    end

    test "updates shade count, curve, role colors, and tween controls",
         %{
           conn: conn
         } do
      {:ok, view, _html} = live(conn, ~p"/en/shader-scale-sketch")

      view
      |> element("button", "Advanced model")
      |> render_click()

      html =
        view
        |> form("#shader-scale-controls",
          shader: %{
            "shade_count" => "5",
            "light_white_point" => "88",
            "light_black_point" => "22",
            "dark_black_point" => "14",
            "dark_white_point" => "78",
            "curve" => "ease-in",
            "curve_strength" => "2",
            "chroma_profile" => "even",
            "surface_chroma" => "0.08",
            "surface_hue" => "252",
            "heading_lightness" => "30",
            "heading_chroma" => "0.07",
            "heading_hue" => "44",
            "body_lightness" => "38",
            "body_chroma" => "0.05",
            "body_hue" => "50",
            "link_lightness" => "42",
            "link_chroma" => "0.18",
            "link_hue" => "246",
            "mode_position" => "64",
            "tween_curve" => "ease-out"
          }
        )
        |> render_change()

      assert html =~ "--shade-count: 5"
      assert html =~ "mode 64% / ease-out"
      assert html =~ "oklch(88%"
      assert html =~ "oklch(14%"
      assert html =~ "oklch(22%"
      assert html =~ "oklch(78%"
      assert html =~ "252deg"
      assert html =~ "273deg"
      assert html =~ "white 88 / black 22 / body 38 / link 42"
    end

    test "surface color controls update the surface-anchored scales without changing reading or action ink",
         %{
           conn: conn
         } do
      {:ok, view, _html} = live(conn, ~p"/en/shader-scale-sketch")

      before =
        view
        |> element(~s|[data-mode="light"] .shader-sketch__grade-sample|)
        |> render()

      updated_html =
        view
        |> form("#shader-scale-controls",
          shader: %{
            "surface_chroma" => "0.11",
            "surface_hue" => "238"
          }
        )
        |> render_change()

      assert before =~ "--grade-background: oklch(94% 0.07 247deg)"
      assert updated_html =~ "--grade-background: oklch(94% 0.11 238deg)"
      assert updated_html =~ "oklch(12% 0.044 259deg)"
      assert updated_html =~ "--grade-body: oklch(40.6% 0.039 54deg)"
      assert updated_html =~ "--grade-link: oklch(46.5% 0.217 252deg)"
      refute updated_html =~ before
    end

    test "light ramp is owned by surface hue from L1 through the generated shades",
         %{
           conn: conn
         } do
      {:ok, view, _html} = live(conn, ~p"/en/shader-scale-sketch")

      view
      |> element("button", "Advanced model")
      |> render_click()

      view
      |> form("#shader-scale-controls",
        shader: %{
          "surface_chroma" => "0.11",
          "surface_hue" => "238"
        }
      )
      |> render_change()

      light_ramp = render(element(view, ~s|[data-ramp="light"]|))

      assert light_ramp =~ "oklch(94% 0.11 238deg)"
      assert light_ramp =~ "oklch(89.836% 0.048 238deg)"
      assert light_ramp =~ "oklch(36% 0.028 238deg)"
      refute light_ramp =~ ~r/class="shader-sketch__swatch-value">[^<]*247deg/
      refute light_ramp =~ ~r/class="shader-sketch__swatch-value">[^<]*259deg/
    end

    test "white and black points own the lightness endpoints for both keyframes",
         %{
           conn: conn
         } do
      {:ok, view, _html} = live(conn, ~p"/en/shader-scale-sketch")

      view
      |> element("button", "Advanced model")
      |> render_click()

      view
      |> form("#shader-scale-controls",
        shader: %{
          "light_white_point" => "88",
          "light_black_point" => "22",
          "dark_black_point" => "14",
          "dark_white_point" => "78",
          "chroma_profile" => "even"
        }
      )
      |> render_change()

      light_ramp = render(element(view, ~s|[data-ramp="light"]|))
      dark_ramp = render(element(view, ~s|[data-ramp="dark"]|))

      assert light_ramp =~ "oklch(88% 0.07 247deg)"
      assert light_ramp =~ "oklch(22% 0.07 247deg)"
      assert dark_ramp =~ "oklch(14% 0.028 268deg)"
      assert dark_ramp =~ "oklch(78% 0.028 268deg)"
    end

    test "reading ink controls update text without changing surface or action ink",
         %{
           conn: conn
         } do
      {:ok, view, _html} = live(conn, ~p"/en/shader-scale-sketch")

      html =
        view
        |> form("#shader-scale-controls",
          shader: %{
            "heading_lightness" => "30",
            "heading_chroma" => "0.08",
            "heading_hue" => "42",
            "body_lightness" => "38",
            "body_chroma" => "0.05",
            "body_hue" => "62"
          }
        )
        |> render_change()

      assert html =~ "--grade-background: oklch(94% 0.07 247deg)"
      assert html =~ "--grade-heading: oklch(30% 0.08 42deg)"
      assert html =~ "--grade-body: oklch(38% 0.05 62deg)"
      assert html =~ "--grade-link: oklch(46.5% 0.217 252deg)"
    end

    test "action ink controls update links without changing surface or reading ink",
         %{
           conn: conn
         } do
      {:ok, view, _html} = live(conn, ~p"/en/shader-scale-sketch")

      before =
        view
        |> element(~s|[data-mode="light"] .shader-sketch__grade-sample|)
        |> render()

      updated_html =
        view
        |> form("#shader-scale-controls",
          shader: %{
            "link_lightness" => "44",
            "link_chroma" => "0.19",
            "link_hue" => "246"
          }
        )
        |> render_change()

      assert before =~ "--grade-link: oklch"
      assert updated_html =~ "--grade-background: oklch(94% 0.07 247deg)"
      assert updated_html =~ "--grade-body: oklch(40.6% 0.039 54deg)"
      assert updated_html =~ "--grade-link: oklch(44% 0.19 246deg)"
      refute updated_html =~ before
    end

    test "advanced model stays open after a value change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/en/shader-scale-sketch")

      html =
        view
        |> element("button", "Advanced model")
        |> render_click()

      assert html =~ ~s(aria-expanded="true")
      assert html =~ "Shade count"
      assert html =~ "Light white point"
      assert html =~ "Light black point"
      assert html =~ "Dark black point"
      assert html =~ "Dark white point"
      refute html =~ "Light scale floor"
      refute html =~ "Dark scale ceiling"
      assert html =~ "Step spacing"
      assert html =~ "Curve strength"
      assert html =~ "Chroma placement"
      assert html =~ "Mix easing"
      refute html =~ "Transition method"
      refute html =~ "value-scale"
      refute html =~ "token-crossfade"
      refute html =~ "Diagnostic ramp tint"
      refute html =~ "Light tint hue"
      refute html =~ "Dark tint hue"

      html =
        view
        |> form("#shader-scale-controls",
          shader: %{
            "shade_count" => "5",
            "mode_position" => "64"
          }
        )
        |> render_change()

      assert html =~ ~s(aria-expanded="true")
      assert html =~ "Shade count"
      assert html =~ "--shade-count: 5"
      assert html =~ "mode 64% / s-curve"
    end

    test "current tween endpoints match the light and dark keyframes", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/en/shader-scale-sketch")

      view
      |> form("#shader-scale-controls", shader: %{"mode_position" => "0"})
      |> render_change()

      assert render(
               element(
                 view,
                 ~s|[data-mode="current"] .shader-sketch__grade-sample|
               )
             ) ==
               render(
                 element(
                   view,
                   ~s|[data-mode="light"] .shader-sketch__grade-sample|
                 )
               )

      view
      |> form("#shader-scale-controls", shader: %{"mode_position" => "100"})
      |> render_change()

      assert render(
               element(
                 view,
                 ~s|[data-mode="current"] .shader-sketch__grade-sample|
               )
             ) ==
               render(
                 element(
                   view,
                   ~s|[data-mode="dark"] .shader-sketch__grade-sample|
                 )
               )
    end

    test "stale removed controls do not affect rendered color state", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/en/shader-scale-sketch")
      selector = ~s|[data-mode="light"] .shader-sketch__grade-sample|
      before = render(element(view, selector))

      render_change(view, :update, %{
        "shader" => %{
          "light_tint" => "0.99",
          "light_tint_hue" => "220",
          "dark_tint" => "0.99",
          "dark_tint_hue" => "310",
          "light_floor" => "0",
          "dark_ceiling" => "100",
          "surface_lightness" => "70",
          "tween_topology" => "token-crossfade"
        }
      })

      assert render(element(view, selector)) == before
    end
  end
end
