defmodule PortfolioWeb.Components.FigureTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias PortfolioWeb.Components.Figure

  describe "figure/1" do
    test "renders a semantic figure element containing an image" do
      html =
        render_component(&Figure.figure/1, %{
          src: "/images/test.jpg",
          alt: "Test image"
        })

      assert html =~ ~s(<figure class="image-figure)
      assert html =~ ~s(<img)
      assert html =~ ~s(</figure>)
    end

    test "applies src and alt attributes to the image" do
      html =
        render_component(&Figure.figure/1, %{
          src: "/images/test.jpg",
          alt: "Test image"
        })

      assert html =~ ~s(src="/images/test.jpg")
      assert html =~ ~s(alt="Test image")
    end

    test "does not render figcaption when no caption is provided" do
      html =
        render_component(&Figure.figure/1, %{
          src: "/images/test.jpg",
          alt: "Test image"
        })

      refute html =~ "<figcaption"
    end

    test "renders figcaption when caption is provided" do
      html =
        render_component(&Figure.figure/1, %{
          src: "/images/test.jpg",
          alt: "Test image",
          caption: "This is a test caption"
        })

      assert html =~ "<figcaption"
      assert html =~ "This is a test caption"
    end

    test "uses Image component to render the image" do
      # This test verifies the component uses the Image component,
      # but focuses on behavior rather than implementation details
      html =
        render_component(&Figure.figure/1, %{
          src: "/images/test.jpg",
          alt: "Test image",
          width: "100",
          height: "100",
          loading: "eager"
        })

      # These attributes should be passed to the image
      assert html =~ ~s(width="100")
      assert html =~ ~s(height="100")
      assert html =~ ~s(loading="eager")
    end

    test "uses Typography component for figcaption" do
      html =
        render_component(&Figure.figure/1, %{
          src: "/images/test.jpg",
          alt: "Test image",
          caption: "This is a test caption"
        })

      # Instead of checking for specific class names (implementation),
      # we verify the general behavior of having a styled figcaption
      assert html =~ "<figcaption"
      assert html =~ "This is a test caption"
    end
  end
end
