defmodule Portfolio.Content.MarkdownRendering.HTMLCompilerTest do
  use Portfolio.DataCase
  alias Portfolio.Content.MarkdownRendering.HTMLCompiler

  describe "render/1" do
    test "renders standard markdown elements to correct HTML" do
      schema_ast = %{
        ast: [
          {"h1", [], ["Heading"], %{}},
          {"p", [], ["Paragraph text"], %{}},
          {"ul", [], [{"li", [], ["List item"], %{}}], %{}}
        ]
      }

      {:ok, html} = HTMLCompiler.render(schema_ast)

      assert html =~ "<h1>Heading</h1>"
      assert html =~ "<p>Paragraph text</p>"
      assert html =~ "<ul><li>List item</li></ul>"
    end

    test "renders nested HTML elements correctly" do
      schema_ast = %{
        ast: [
          {"div", [],
           [
             {"h2", [], ["Subheading"], %{}},
             {"p", [], ["Nested paragraph."], %{}}
           ], %{}}
        ]
      }

      {:ok, html} = HTMLCompiler.render(schema_ast)
      assert html == "<div><h2>Subheading</h2><p>Nested paragraph.</p></div>"
    end

    test "renders HTML elements with attributes correctly" do
      schema_ast = %{
        ast: [
          {"p", [{"class", "text-large"}, {"id", "intro"}],
           ["Welcome to our site!"], %{}}
        ]
      }

      {:ok, html} = HTMLCompiler.render(schema_ast)

      assert html ==
               "<p class=\"text-large\" id=\"intro\">Welcome to our site!</p>"
    end
  end

  describe "transform/1 with custom elements" do
    test "renders custom image elements with attributes and caption correctly" do
      custom_image_ast =
        {:custom_image, "alt text", "image_src.jpg",
         %{
           "caption" => "Image Caption",
           "srcset" => "image_1x.jpg 1x, image_2x.jpg 2x"
         }}

      html = HTMLCompiler.transform(custom_image_ast)

      expected_html = """
      <figure class="responsive-image">
        <img src="image_src.jpg" alt="alt text" srcset="image_1x.jpg 1x, image_2x.jpg 2x">
        <figcaption>Image Caption</figcaption>
      </figure>
      """

      assert html == expected_html
    end
  end

  describe "transform/4" do
    test "renders custom image with all attributes" do
      attrs = %{
        "caption" => "Image Caption",
        "srcset" => "image_1x.jpg 1x, image_2x.jpg 2x"
      }

      custom_image_ast = {:custom_image, "alt text", "image_src.jpg", attrs}

      html = HTMLCompiler.transform(custom_image_ast)

      assert html == """
             <figure class="responsive-image">
               <img src="image_src.jpg" alt="alt text" srcset="image_1x.jpg 1x, image_2x.jpg 2x">
               <figcaption>Image Caption</figcaption>
             </figure>
             """
    end

    test "handles missing attributes gracefully" do
      custom_image_ast = {:custom_image, "alt text", "image_src.jpg", %{}}

      html = HTMLCompiler.transform(custom_image_ast)

      assert html == """
             <figure class="responsive-image">
               <img src="image_src.jpg" alt="alt text" srcset="">
               <figcaption></figcaption>
             </figure>
             """
    end
  end
end