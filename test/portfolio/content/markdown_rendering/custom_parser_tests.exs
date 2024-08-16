defmodule Portfolio.Content.MarkdownRendering.CustomParserTest do
  use Portfolio.DataCase

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
               {"h2", [], ["Heading 2"], %{}},
               {"p", [], ["This is a paragraph."], %{}},
               {"ul", [],
                [
                  {"li", [], ["List item 1"], %{}},
                  {"li", [], ["List item 2"], %{}}
                ], %{}}
             ] == ast
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
               match?({"h1", _, ["Content"], _}, node)
             end)
    end
  end
end
