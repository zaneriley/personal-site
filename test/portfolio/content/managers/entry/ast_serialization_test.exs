defmodule Portfolio.Content.Managers.Entry.AstSerializationTest do
  use ExUnit.Case, async: true
  alias Portfolio.Content.Managers.Entry.AstSerialization

  describe "serialize_ast/1" do
    test "serializes a simple text node" do
      ast = ["Simple text node"]
      serialized = AstSerialization.serialize_ast(ast)

      assert [%{type: "text", content: "Simple text node"}] = serialized
    end

    test "serializes a simple HTML element node" do
      ast = [{"p", [], ["Paragraph text"], %{}}]
      serialized = AstSerialization.serialize_ast(ast)

      assert [
               %{
                 type: "element",
                 tag: "p",
                 attrs: %{},
                 content: [%{type: "text", content: "Paragraph text"}],
                 meta: %{}
               }
             ] = serialized
    end

    test "serializes a typography node" do
      ast = [{:typography, "h1", %{size: "xl"}, ["Heading"], %{}}]
      serialized = AstSerialization.serialize_ast(ast)

      assert [
               %{
                 type: "typography",
                 tag: "h1",
                 attrs: %{"size" => "xl"},
                 content: [%{type: "text", content: "Heading"}],
                 meta: %{}
               }
             ] = serialized
    end

    test "serializes a component node" do
      ast = [{:component, :button, %{variant: "primary"}, ["Click me"], %{}}]
      serialized = AstSerialization.serialize_ast(ast)

      assert [
               %{
                 type: "component",
                 component_type: :button,
                 attrs: %{"variant" => "primary"},
                 content: [%{type: "text", content: "Click me"}],
                 meta: %{}
               }
             ] = serialized
    end

    test "serializes complex nested structures" do
      ast = [
        {"div", [class: "container"],
         [
           {:typography, "h1", %{size: "4xl"}, ["Main Heading"], %{}},
           {"p", [], ["Introduction paragraph"], %{}},
           {:component, :callout, %{type: "info"},
            [
              {"p", [], ["Important information"], %{}}
            ], %{}}
         ], %{}}
      ]

      serialized = AstSerialization.serialize_ast(ast)

      assert [
               %{
                 type: "element",
                 tag: "div",
                 attrs: %{"class" => "container"},
                 content: [
                   %{
                     type: "typography",
                     tag: "h1",
                     attrs: %{"size" => "4xl"},
                     content: [%{type: "text", content: "Main Heading"}],
                     meta: %{}
                   },
                   %{
                     type: "element",
                     tag: "p",
                     attrs: %{},
                     content: [
                       %{type: "text", content: "Introduction paragraph"}
                     ],
                     meta: %{}
                   },
                   %{
                     type: "component",
                     component_type: :callout,
                     attrs: %{"type" => "info"},
                     content: [
                       %{
                         type: "element",
                         tag: "p",
                         attrs: %{},
                         content: [
                           %{type: "text", content: "Important information"}
                         ],
                         meta: %{}
                       }
                     ],
                     meta: %{}
                   }
                 ],
                 meta: %{}
               }
             ] = serialized
    end
  end

  describe "deserialize_ast/1" do
    test "deserializes a simple text node" do
      serialized = [%{type: "text", content: "Simple text node"}]
      deserialized = AstSerialization.deserialize_ast(serialized)

      assert ["Simple text node"] = deserialized
    end

    test "deserializes a simple HTML element node" do
      serialized = [
        %{
          type: "element",
          tag: "p",
          attrs: %{},
          content: [%{type: "text", content: "Paragraph text"}],
          meta: %{}
        }
      ]

      deserialized = AstSerialization.deserialize_ast(serialized)

      assert [{"p", %{}, ["Paragraph text"], %{}}] = deserialized
    end

    test "deserializes a typography node" do
      serialized = [
        %{
          type: "typography",
          tag: "h1",
          attrs: %{"size" => "xl"},
          content: [%{type: "text", content: "Heading"}],
          meta: %{}
        }
      ]

      deserialized = AstSerialization.deserialize_ast(serialized)

      assert [{:typography, "h1", %{"size" => "xl"}, ["Heading"], %{}}] =
               deserialized
    end

    test "deserializes a component node" do
      serialized = [
        %{
          type: "component",
          component_type: :button,
          attrs: %{"variant" => "primary"},
          content: [%{type: "text", content: "Click me"}],
          meta: %{}
        }
      ]

      deserialized = AstSerialization.deserialize_ast(serialized)

      assert [
               {:component, :button, %{"variant" => "primary"}, ["Click me"],
                %{}}
             ] = deserialized
    end

    test "deserializes complex nested structures" do
      serialized = [
        %{
          type: "element",
          tag: "div",
          attrs: %{"class" => "container"},
          content: [
            %{
              type: "typography",
              tag: "h1",
              attrs: %{"size" => "4xl"},
              content: [%{type: "text", content: "Main Heading"}],
              meta: %{}
            },
            %{
              type: "element",
              tag: "p",
              attrs: %{},
              content: [%{type: "text", content: "Introduction paragraph"}],
              meta: %{}
            },
            %{
              type: "component",
              component_type: :callout,
              attrs: %{"type" => "info"},
              content: [
                %{
                  type: "element",
                  tag: "p",
                  attrs: %{},
                  content: [%{type: "text", content: "Important information"}],
                  meta: %{}
                }
              ],
              meta: %{}
            }
          ],
          meta: %{}
        }
      ]

      deserialized = AstSerialization.deserialize_ast(serialized)

      assert [
               {"div", %{"class" => "container"},
                [
                  {:typography, "h1", %{"size" => "4xl"}, ["Main Heading"],
                   %{}},
                  {"p", %{}, ["Introduction paragraph"], %{}},
                  {:component, :callout, %{"type" => "info"},
                   [
                     {"p", %{}, ["Important information"], %{}}
                   ], %{}}
                ], %{}}
             ] = deserialized
    end
  end

  describe "roundtrip serialization and deserialization" do
    test "maintains original structure through serialize and deserialize" do
      original_ast = [
        {"div", [class: "container"],
         [
           {:typography, "h1", %{size: "4xl"}, ["Main Heading"], %{}},
           {"p", [], ["Introduction paragraph"], %{}},
           {:component, :callout, %{type: "info"},
            [
              {"p", [], ["Important information"], %{}}
            ], %{}}
         ], %{}}
      ]

      serialized = AstSerialization.serialize_ast(original_ast)
      deserialized = AstSerialization.deserialize_ast(serialized)

      # Check key structural elements
      assert length(deserialized) == length(original_ast)

      deserialized_div = hd(deserialized)
      assert is_tuple(deserialized_div)
      assert elem(deserialized_div, 0) == "div"

      # Check children exist
      children = elem(deserialized_div, 2)
      assert length(children) == 3

      # Check the typography element
      typography_node = Enum.at(children, 0)
      assert elem(typography_node, 0) == :typography
      assert elem(typography_node, 1) == "h1"
      assert elem(typography_node, 2)["size"] == "4xl"

      # Check the component element
      component_node = Enum.at(children, 2)
      assert elem(component_node, 0) == :component
      assert elem(component_node, 1) == :callout
    end
  end

  describe "edge cases" do
    test "handles empty lists" do
      assert AstSerialization.serialize_ast([]) == []
      assert AstSerialization.deserialize_ast([]) == []
    end

    test "handles unknown node types" do
      ast = [{:unknown_type, "value"}]
      serialized = AstSerialization.serialize_ast(ast)

      assert [%{type: "unknown", content: _}] = serialized
    end

    test "handles nil attributes" do
      ast = [{"div", nil, [], %{}}]
      serialized = AstSerialization.serialize_ast(ast)

      assert [
               %{
                 type: "element",
                 tag: "div",
                 attrs: %{},
                 content: [],
                 meta: %{}
               }
             ] = serialized
    end
  end
end
