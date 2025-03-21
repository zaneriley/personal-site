defmodule Portfolio.Content.MarkdownRendering.CustomParserTest do
  use Portfolio.DataCase
  import ExUnit.CaptureLog

  alias Portfolio.Content.MarkdownRendering.CustomParser

  describe "parse/1" do
    test "parses standard markdown elements correctly" do
      markdown = """
      ## Heading 2

      This is a paragraph.

      * List item 1
      * List item 2
      """

      {:ok, result} = CustomParser.parse(markdown)
      # Extract the AST from the result map
      ast = result.ast

      assert [
               {:typography, "h2", %{font: "cardinal", size: "3xl"},
                ["Heading 2"], %{}},
               {:typography, "p", %{size: "md"}, ["This is a paragraph."],
                %{dropcap: true}},
               {"ul", [],
                [
                  {"li", [], ["List item 1"], %{}},
                  {"li", [], ["List item 2"], %{}}
                ], %{}}
             ] == ast
    end

    # New test for image to figure transformation
    test "transforms markdown images to figure components" do
      markdown = """
      # Test Images

      ![Test image](test-image.jpg)

      Regular paragraph.
      """

      {:ok, result} = CustomParser.parse(markdown)
      ast = result.ast

      # First element should be h1 typography
      [h1_node, figure_node, p_node] = ast

      # Verify the figure transformation
      assert {:component, :figure, attrs, [], _meta} = figure_node
      assert attrs.src == "test-image.jpg"
      assert attrs.alt == "Test image"
      assert attrs.caption == nil
    end

    # New test for image with caption (image followed by italicized text)
    test "transforms markdown images with captions to figure components with captions" do
      markdown = """
      # Test Images with Captions

      ![Test image](test-image.jpg)
      *This is a caption for the image*

      Regular paragraph.
      """

      {:ok, result} = CustomParser.parse(markdown)
      ast = result.ast

      # First element should be h1 typography
      [h1_node, figure_node, p_node] = ast

      # Verify the figure transformation with caption
      assert {:component, :figure, attrs, [], _meta} = figure_node
      assert attrs.src == "test-image.jpg"
      assert attrs.alt == "Test image"
      assert attrs.caption == "This is a caption for the image"
    end

    # Not implemented yet
    @tag :skip
    test "handles basic custom UI components" do
      markdown = """
      :p This is a custom paragraph component.
      """

      {:ok, ast} = CustomParser.parse(markdown)

      assert [
               {:p, [], ["This is a custom paragraph component."], %{}}
             ] = ast
    end

    # New test for custom delimiter syntax components
    test "parses custom component syntax with delimiters" do
      markdown = """
      # Custom Components

      ::carousel{title="Project Images" autoplay=true}
      ![Image 1](image1.jpg)
      *Caption 1*

      ![Image 2](image2.jpg)
      *Caption 2*
      ::end-carousel

      Regular paragraph after component.
      """

      {:ok, result} = CustomParser.parse(markdown)
      ast = result.ast

      # First element should be h1 typography
      [h1_node, carousel_node, p_node] = ast

      # Verify the carousel component
      assert {:component, :carousel, attrs, content, _meta} = carousel_node
      assert attrs.title == "Project Images"
      assert attrs.autoplay == true

      # Carousel should contain figure components
      assert length(content) == 2
      assert {:component, :figure, figure1_attrs, [], _} = Enum.at(content, 0)
      assert figure1_attrs.src == "image1.jpg"
      assert figure1_attrs.caption == "Caption 1"
    end

    test "preserves metadata and frontmatter" do
      markdown = """
      ---
      title: Test Case Study
      company: ACME Corp
      ---
      # Content
      """

      {:ok, %{frontmatter: frontmatter, ast: ast}} =
        CustomParser.parse(markdown)

      assert frontmatter == "title: Test Case Study\ncompany: ACME Corp\n"

      assert Enum.any?(ast, fn node ->
               match?(
                 {:typography, "h1", %{font: "cardinal", size: "4xl"},
                  ["Content"], %{}},
                 node
               )
             end)
    end

    test "handles error cases correctly" do
      markdown = "```\nUnclosed code block"

      log =
        capture_log(fn ->
          result = CustomParser.parse(markdown)
          assert {:error, "Error parsing markdown"} = result
        end)

      assert log =~ "Error parsing markdown:"
    end

    test "correctly splits frontmatter and content" do
      markdown = """
      ---
      title: Test Title
      date: 2023-04-14
      ---
      # Main Content
      This is the main content of the markdown.
      """

      {frontmatter, content} = CustomParser.split_frontmatter(markdown)

      assert frontmatter == "title: Test Title\ndate: 2023-04-14\n"

      assert content ==
               "# Main Content\nThis is the main content of the markdown.\n"
    end
  end
end
