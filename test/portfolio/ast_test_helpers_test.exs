defmodule Portfolio.AstTestHelpersTest do
  use ExUnit.Case, async: true

  alias Portfolio.AstTestHelpers

  describe "extract_text/1" do
    test "handles simple strings" do
      assert AstTestHelpers.extract_text("Simple text") == "Simple text"
    end

    test "handles lists of strings" do
      assert AstTestHelpers.extract_text(["Hello", " ", "world"]) ==
               "Hello world"
    end

    test "handles typography nodes" do
      ast = [{:typography, "h1", %{size: "4xl"}, ["Heading"], %{}}]
      assert AstTestHelpers.extract_text(ast) == "Heading"
    end

    test "handles nested typography nodes" do
      ast = [
        {:typography, "h1", %{size: "4xl"},
         ["Main ", {"em", %{}, ["Heading"], %{}}], %{}},
        {:typography, "p", %{}, ["Paragraph text"], %{}}
      ]

      assert AstTestHelpers.extract_text(ast) == "Main HeadingParagraph text"
    end

    test "handles component nodes" do
      ast = [
        {:component, :image, %{alt: "Alt text", src: "path/to/image.jpg"}, [],
         %{}}
      ]

      assert AstTestHelpers.extract_text(ast) == "Alt text"
    end

    test "handles mixed node types" do
      ast = [
        {:typography, "h1", %{}, ["Heading"], %{}},
        {:typography, "p", %{},
         [
           "This is a paragraph with ",
           {"em", %{}, ["emphasized"], %{}},
           " and ",
           {"strong", %{}, ["strong"], %{}},
           " text."
         ], %{}},
        {:component, :image, %{alt: "An image", src: "path/to/image.jpg"}, [],
         %{}},
        {"ul", %{},
         [
           {"li", %{}, ["List item 1"], %{}},
           {"li", %{}, ["List item 2"], %{}}
         ], %{}}
      ]

      expected =
        "HeadingThis is a paragraph with emphasized and strong text.An imageList item 1List item 2"

      assert AstTestHelpers.extract_text(ast) == expected
    end

    test "handles empty or nil values" do
      assert AstTestHelpers.extract_text([]) == ""
      assert AstTestHelpers.extract_text(nil) == ""
    end
  end
end
