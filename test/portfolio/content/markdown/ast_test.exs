defmodule Portfolio.Content.Markdown.AstTest do
  use ExUnit.Case, async: true

  # Module doesn't exist yet, but we're defining tests first per TDD
  alias Portfolio.Content.Markdown.Ast

  describe "traverse/2" do
    test "transforms AST nodes using provided function" do
      ast = [
        {"div", [],
         [
           {"h1", [], ["Heading"], %{}},
           {"p", [], ["Paragraph"], %{}}
         ], %{}}
      ]

      # Function that converts all element nodes to uppercase tags
      transform_fn = fn
        {tag, attrs, children, meta} when is_binary(tag) ->
          {String.upcase(tag), attrs, children, meta}

        node ->
          node
      end

      result = Ast.traverse(ast, transform_fn)

      assert [
               {"DIV", [],
                [
                  {"H1", [], ["Heading"], %{}},
                  {"P", [], ["Paragraph"], %{}}
                ], %{}}
             ] = result
    end

    test "handles nested components and mixed content" do
      ast = [
        {:component, "card", %{},
         [
           {"h2", [], ["Card Title"], %{}},
           {:component, "button", %{}, ["Click Me"], %{}}
         ], %{}}
      ]

      # Function that adds a class to all component nodes
      transform_fn = fn
        {:component, name, attrs, children, meta} ->
          {:component, name, Map.put(attrs, :class, "enhanced"), children, meta}

        node ->
          node
      end

      result = Ast.traverse(ast, transform_fn)

      assert [
               {:component, "card", %{class: "enhanced"},
                [
                  {"h2", [], ["Card Title"], %{}},
                  {:component, "button", %{class: "enhanced"}, ["Click Me"],
                   %{}}
                ], %{}}
             ] = result
    end
  end

  describe "find_nodes/2" do
    test "finds nodes matching criteria" do
      ast = [
        {"div", [],
         [
           {"h1", [], ["Heading 1"], %{}},
           {"h2", [], ["Heading 2"], %{}},
           {"p", [], ["Paragraph"], %{}}
         ], %{}}
      ]

      # Find all heading nodes
      headings =
        Ast.find_nodes(ast, fn
          {tag, _, _, _} when tag in ["h1", "h2", "h3", "h4", "h5", "h6"] ->
            true

          _ ->
            false
        end)

      assert length(headings) == 2
      assert Enum.at(headings, 0) == {"h1", [], ["Heading 1"], %{}}
      assert Enum.at(headings, 1) == {"h2", [], ["Heading 2"], %{}}
    end
  end
end
