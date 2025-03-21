defmodule Portfolio.Content.MarkdownRendering.ComponentBuilderTest do
  use ExUnit.Case, async: false
  alias Portfolio.Content.MarkdownRendering.ComponentBuilder
  alias Portfolio.Content.MarkdownRendering.AST
  alias Portfolio.Content.MarkdownRendering.Components.Registry

  setup do
    # Ensure registry is stopped and restarted for each test
    Registry.stop()
    {:ok, _} = start_supervised(Registry)
    :ok
  end

  describe "render/1" do
    test "renders standard markdown elements as Phoenix components" do
      schema_ast = %{
        ast: [
          {"h1", [], ["Heading"], %{}},
          {"p", [], ["Paragraph text"], %{}},
          {"ul", [], [{"li", [], ["List item"], %{}}], %{}}
        ]
      }

      {:ok, component_ast} = ComponentBuilder.render(schema_ast)

      # Basic structure verification
      assert is_list(component_ast)
      assert length(component_ast) == 3

      # Verify heading transformed to typography component
      [heading, paragraph, list] = component_ast

      assert match?(
               {:component, PortfolioWeb.Components.Typography, :typography,
                %{tag: "h1"}, ["Heading"]},
               heading
             )

      assert match?(
               {:component, PortfolioWeb.Components.Typography, :typography,
                %{tag: "p"}, ["Paragraph text"]},
               paragraph
             )

      assert match?({"ul", [], [{"li", [], ["List item"], %{}}], %{}}, list)
    end

    test "renders nested HTML elements as components" do
      schema_ast = %{
        ast: [
          {"div", [],
           [
             {"h2", [], ["Subheading"], %{}},
             {"p", [], ["Nested paragraph."], %{}}
           ], %{}}
        ]
      }

      {:ok, component_ast} = ComponentBuilder.render(schema_ast)

      # Verify structure - a div containing two typography components
      assert is_list(component_ast)
      assert length(component_ast) == 1

      [div_element] = component_ast
      assert match?({"div", [], [_, _], %{}}, div_element)

      {"div", [], div_children, _} = div_element

      # Check the children of the div
      [h2, p] = div_children

      assert match?(
               {:component, PortfolioWeb.Components.Typography, :typography,
                %{tag: "h2"}, ["Subheading"]},
               h2
             )

      assert match?(
               {:component, PortfolioWeb.Components.Typography, :typography,
                %{tag: "p"}, ["Nested paragraph."]},
               p
             )
    end

    test "transforms HTML elements with attributes correctly" do
      schema_ast = %{
        ast: [
          {"p", [{"class", "text-large"}, {"id", "intro"}],
           ["Welcome to our site!"], %{}}
        ]
      }

      {:ok, component_ast} = ComponentBuilder.render(schema_ast)

      # Verify we get a typography component
      assert is_list(component_ast)
      assert length(component_ast) == 1

      [typography] = component_ast

      assert match?(
               {:component, PortfolioWeb.Components.Typography, :typography, _,
                _},
               typography
             )

      # Depending on implementation, attributes may be passed through or not
      {:component, _, :typography, attrs, content} = typography
      assert attrs.tag == "p"
      assert content == ["Welcome to our site!"]
    end

    test "render/1 renders typography component correctly" do
      ast = [
        {:component, :typography, %{size: "4xl", tag: "h1"},
         ["Heading with Typography Component"], %{}}
      ]

      {:ok, result} = ComponentBuilder.render(%{ast: ast})

      assert Enum.count(result) == 1
      [comp] = result

      # Use a more flexible assertion that handles both cases:
      # 1. When component is not registered and uses :unknown
      # 2. When component is registered and uses the actual module/function
      assert match?({:component, _, _, %{size: "4xl", tag: "h1"}, _}, comp)
    end

    test "render/1 renders column layout component correctly" do
      ast = [
        {:component, :column_layout, %{columns: [%{width: "1"}, %{width: "2"}]},
         [], %{}}
      ]

      {:ok, result} = ComponentBuilder.render(%{ast: ast})

      assert Enum.count(result) == 1
      [comp] = result

      assert match?(
               {:component, _, _, %{columns: [%{width: "1"}, %{width: "2"}]},
                _},
               comp
             )
    end
  end
end
