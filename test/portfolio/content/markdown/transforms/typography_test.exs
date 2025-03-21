defmodule Portfolio.Content.Markdown.Transforms.TypographyTest do
  use ExUnit.Case, async: true

  alias Portfolio.Content.Markdown.Transforms.Typography

  describe "apply/2" do
    test "transforms heading elements into typography components" do
      # Create an AST with heading elements
      ast = [
        {"h1", [], ["Heading 1"], %{}},
        {"h2", [], ["Heading 2"], %{}},
        {"h3", [], ["Heading 3"], %{}}
      ]

      # Apply the transform
      {:ok, transformed_ast} = Typography.apply(ast)

      # Check that all heading elements were transformed to typography components
      assert [h1, h2, h3] = transformed_ast

      # Verify h1 transformation
      assert {:typography, "h1", h1_attrs, ["Heading 1"], _} = h1
      assert h1_attrs[:size] == "4xl"
      assert h1_attrs[:font] == "cardinal"

      # Verify h2 transformation
      assert {:typography, "h2", h2_attrs, ["Heading 2"], _} = h2
      assert h2_attrs[:size] == "3xl"
      assert h2_attrs[:font] == "cardinal"

      # Verify h3 transformation
      assert {:typography, "h3", h3_attrs, ["Heading 3"], _} = h3
      assert h3_attrs[:size] == "2xl"
      assert h3_attrs[:font] == "cardinal"
    end

    test "applies dropcap to first paragraph only" do
      # Create an AST with multiple paragraphs
      ast = [
        {"p", [], ["First paragraph"], %{}},
        {"p", [], ["Second paragraph"], %{}}
      ]

      # Apply the transform
      {:ok, transformed_ast} = Typography.apply(ast)

      # Check that both paragraphs were transformed
      assert [p1, p2] = transformed_ast

      # Verify first paragraph has dropcap
      assert {:typography, "p", p1_attrs, ["First paragraph"], _} = p1
      assert p1_attrs[:dropcap] == true
      assert p1_attrs[:size] == "md"

      # Verify second paragraph does not have dropcap
      assert {:typography, "p", p2_attrs, ["Second paragraph"], _} = p2
      assert p2_attrs[:dropcap] != true
      assert p2_attrs[:size] == "md"
    end

    test "can disable dropcap with options" do
      # Create an AST with a paragraph
      ast = [{"p", [], ["First paragraph"], %{}}]

      # Apply the transform with dropcap disabled
      {:ok, transformed_ast} =
        Typography.apply(ast, first_paragraph_dropcap: false)

      # Verify paragraph does not have dropcap
      assert [p] = transformed_ast
      assert {:typography, "p", p_attrs, ["First paragraph"], _} = p
      assert p_attrs[:dropcap] != true
    end

    test "processes nested content recursively" do
      # Create an AST with nested elements
      ast = [
        {"div", [],
         [
           {"h1", [], ["Nested Heading"], %{}},
           {"p", [], ["Nested Paragraph"], %{}}
         ], %{}}
      ]

      # Apply the transform
      {:ok, transformed_ast} = Typography.apply(ast)

      # Check the structure was maintained
      assert [div] = transformed_ast
      assert {"div", [], div_content, %{}} = div

      # Check that nested elements were transformed
      assert [h1, p] = div_content
      assert {:typography, "h1", _, ["Nested Heading"], _} = h1
      assert {:typography, "p", p_attrs, ["Nested Paragraph"], _} = p

      # First paragraph inside a div should still get dropcap
      assert p_attrs[:dropcap] == true
    end

    test "preserves component nodes and processes their content" do
      # Create an AST with a component node
      ast = [
        {:component, :test_component, %{attr: "value"},
         [
           {"p", [], ["Component Content"], %{}}
         ], %{}}
      ]

      # Apply the transform
      {:ok, transformed_ast} = Typography.apply(ast)

      # Check component structure was preserved
      assert [component] = transformed_ast

      assert {:component, :test_component, %{attr: "value"}, component_content,
              %{}} = component

      # Check that content inside component was transformed
      assert [p] = component_content
      assert {:typography, "p", p_attrs, ["Component Content"], _} = p
      assert p_attrs[:dropcap] == true
    end

    test "applies custom heading sizes from options" do
      # Create an AST with headings
      ast = [
        {"h1", [], ["Custom Size Heading"], %{}},
        {"h2", [], ["Another Heading"], %{}}
      ]

      # Apply the transform with custom heading sizes
      custom_sizes = %{
        "h1" => "custom-xl",
        "h2" => "custom-lg"
      }

      {:ok, transformed_ast} =
        Typography.apply(ast, heading_sizes: custom_sizes)

      # Verify custom sizes were applied
      assert [h1, h2] = transformed_ast
      assert {:typography, "h1", h1_attrs, _, _} = h1
      assert h1_attrs[:size] == "custom-xl"

      assert {:typography, "h2", h2_attrs, _, _} = h2
      assert h2_attrs[:size] == "custom-lg"
    end
  end
end
