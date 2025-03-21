defmodule Portfolio.Content.Markdown.ParserTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Portfolio.Content.Markdown.Parser

  describe "parse/1" do
    test "parses simple markdown correctly" do
      markdown = """
      # Heading 1

      This is a paragraph.

      ## Heading 2

      * List item 1
      * List item 2
      """

      {:ok, %{frontmatter: frontmatter, ast: ast}} = Parser.parse(markdown)

      # Check frontmatter
      assert frontmatter == %{}

      # Check basic structure of AST
      assert length(ast) == 4

      # Check heading elements
      assert {"h1", _, ["Heading 1"], _} = Enum.at(ast, 0)
      assert {"p", _, ["This is a paragraph."], _} = Enum.at(ast, 1)
      assert {"h2", _, ["Heading 2"], _} = Enum.at(ast, 2)

      # Check list element
      assert {"ul", _, list_items, _} = Enum.at(ast, 3)
      assert length(list_items) == 2
      assert {"li", _, ["List item 1"], _} = Enum.at(list_items, 0)
      assert {"li", _, ["List item 2"], _} = Enum.at(list_items, 1)
    end

    test "extracts and parses frontmatter correctly" do
      markdown = """
      ---
      title: Test Document
      author: Test Author
      tags:
        - test
        - markdown
      ---

      # Content with Frontmatter
      """

      {:ok, %{frontmatter: frontmatter, ast: ast}} = Parser.parse(markdown)

      # Check frontmatter
      assert frontmatter["title"] == "Test Document"
      assert frontmatter["author"] == "Test Author"
      assert frontmatter["tags"] == ["test", "markdown"]

      # Check AST
      assert [{"h1", _, ["Content with Frontmatter"], _}] = ast
    end

    test "handles error cases gracefully" do
      # Malformed markdown with unclosed code block
      markdown = "```\nUnclosed code block"

      log =
        capture_log(fn ->
          result = Parser.parse(markdown)
          assert {:error, "Error parsing markdown"} = result
        end)

      assert log =~ "Error parsing markdown"
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

      {frontmatter, content} = Parser.split_frontmatter(markdown)

      assert frontmatter["title"] == "Test Title"
      assert frontmatter["date"] == "2023-04-14"

      assert content =~ "# Main Content"
      assert content =~ "This is the main content of the markdown."
    end

    test "returns empty map for frontmatter when none exists" do
      markdown = "# Just content\nNo frontmatter here."

      {frontmatter, content} = Parser.split_frontmatter(markdown)

      assert frontmatter == %{}
      assert content == markdown
    end
  end
end
