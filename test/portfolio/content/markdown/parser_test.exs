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

  describe "parse/1 fenced code with filenames" do
    test "a fence with a filename in the info string still parses as a code block" do
      markdown = """
      ```elixir lib/push_search/accounts.ex
      :ok
      ```
      """

      assert {:ok, %{ast: ast}} = Parser.parse(markdown)

      assert [{"pre", _, [{"code", attrs, [":ok"], _}], _}] = ast
      assert {"class", "elixir"} in attrs
      assert {"data-filename", "lib/push_search/accounts.ex"} in attrs
    end

    test "multiple fences keep their own filenames in order" do
      markdown = """
      ```elixir lib/a.ex
      :a
      ```

      ```rust
      let b = 1;
      ```

      ```css src/c.css
      .c { color: red; }
      ```
      """

      assert {:ok, %{ast: ast}} = Parser.parse(markdown)

      fences =
        for {"pre", _, [{"code", attrs, _, _}], _} <- ast do
          {attr(attrs, "class"), attr(attrs, "data-filename")}
        end

      assert fences == [
               {"elixir", "lib/a.ex"},
               {"rust", nil},
               {"css", "src/c.css"}
             ]
    end

    test "a fence with no info string is untouched" do
      markdown = """
      ```
      plain
      ```
      """

      assert {:ok, %{ast: ast}} = Parser.parse(markdown)
      assert [{"pre", _, [{"code", attrs, ["plain"], _}], _}] = ast
      assert attr(attrs, "data-filename") == nil
    end

    test "code fences inside the document body don't disturb surrounding content" do
      markdown = """
      # Title

      ```elixir lib/a.ex
      :ok
      ```

      After.
      """

      assert {:ok, %{ast: ast}} = Parser.parse(markdown)

      assert [
               {"h1", _, ["Title"], _},
               {"pre", _, _, _},
               {"p", _, ["After."], _}
             ] = ast
    end
  end

  defp attr(attrs, key) do
    Enum.find_value(attrs, fn
      {^key, value} -> value
      _ -> nil
    end)
  end
end
