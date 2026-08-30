defmodule PortfolioWeb.Components.ImageTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias PortfolioWeb.Components.Image

  describe "image/1" do
    test "renders an img element with src and alt attributes" do
      html =
        render_component(&Image.image/1, %{
          src: "/images/test.jpg",
          alt: "Test image"
        })

      assert html =~ "<img"
      assert html =~ ~s(src="/images/test.jpg")
      assert html =~ ~s(alt="Test image")
    end

    test "applies default lazy loading attribute" do
      html =
        render_component(&Image.image/1, %{
          src: "/images/test.jpg",
          alt: "Test image"
        })

      assert html =~ ~s(loading="lazy")
    end

    test "allows overriding the loading attribute" do
      html =
        render_component(&Image.image/1, %{
          src: "/images/test.jpg",
          alt: "Test image",
          loading: "eager"
        })

      assert html =~ ~s(loading="eager")
    end

    test "applies optional width and height attributes when provided" do
      html =
        render_component(&Image.image/1, %{
          src: "/images/test.jpg",
          alt: "Test image",
          width: "200",
          height: "150"
        })

      assert html =~ ~s(width="200")
      assert html =~ ~s(height="150")
    end

    test "applies custom classes when provided" do
      html =
        render_component(&Image.image/1, %{
          src: "/images/test.jpg",
          alt: "Test image",
          class: "custom-class"
        })

      assert html =~ ~s(class="custom-class")
    end
  end
end
