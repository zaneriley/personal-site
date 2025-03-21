defmodule Portfolio.Content.MarkdownRendering.Components.DefinitionTest do
  use ExUnit.Case, async: false

  alias Portfolio.Content.MarkdownRendering.Components.Definition

  describe "validate_attributes/2" do
    test "validates required attributes" do
      specs = %{
        size: %{type: :string, required: true},
        color: %{type: :string, required: false, default: "black"}
      }

      # Valid attributes with required field
      assert {:ok, %{size: "large", color: "black"}} =
               Definition.validate_attributes(%{size: "large"}, specs)

      # Missing required field
      assert {:error, "Missing required attribute: size"} =
               Definition.validate_attributes(%{}, specs)
    end

    test "applies default values" do
      specs = %{
        size: %{type: :string, required: true},
        color: %{type: :string, required: false, default: "black"},
        width: %{type: :integer, required: false, default: 100}
      }

      assert {:ok, %{size: "medium", color: "black", width: 100}} =
               Definition.validate_attributes(%{size: "medium"}, specs)
    end

    test "validates attribute types" do
      specs = %{
        size: %{type: :string, required: true},
        count: %{type: :integer, required: true},
        enabled: %{type: :boolean, required: true},
        options: %{type: :list, required: true}
      }

      # Valid attributes
      attrs = %{
        size: "small",
        count: 5,
        enabled: true,
        options: ["a", "b", "c"]
      }

      assert {:ok, _} = Definition.validate_attributes(attrs, specs)

      # Invalid type
      attrs = %{
        size: "small",
        # should be integer
        count: "five",
        enabled: true,
        options: ["a", "b", "c"]
      }

      assert {:error, msg} = Definition.validate_attributes(attrs, specs)
      assert String.contains?(msg, "does not match type")
    end

    test "validates multiple allowed types" do
      specs = %{
        value: %{type: [:string, :integer], required: true}
      }

      # String is valid
      assert {:ok, %{value: "test"}} =
               Definition.validate_attributes(%{value: "test"}, specs)

      # Integer is valid
      assert {:ok, %{value: 123}} =
               Definition.validate_attributes(%{value: 123}, specs)

      # Boolean is invalid
      assert {:error, _} =
               Definition.validate_attributes(%{value: true}, specs)
    end
  end

  describe "generate_docs/1" do
    test "generates documentation from metadata" do
      metadata = %{
        description: "A test component",
        attributes: %{
          size: %{
            type: :string,
            required: true,
            description: "Size of component"
          },
          color: %{
            type: :string,
            required: false,
            default: "black",
            description: "Color of component"
          }
        },
        slots: [
          %{
            name: :content,
            description: "Main content slot",
            attributes: %{
              align: %{
                type: :string,
                required: false,
                default: "left",
                description: "Content alignment"
              }
            }
          }
        ],
        examples: ["<Example>Test</Example>"]
      }

      docs = Definition.generate_docs(metadata)

      # Check for key sections
      assert String.contains?(docs, "## Description")
      assert String.contains?(docs, "A test component")
      assert String.contains?(docs, "## Attributes")
      assert String.contains?(docs, "size")
      assert String.contains?(docs, "color")
      assert String.contains?(docs, "## Slots")
      assert String.contains?(docs, "content")
      assert String.contains?(docs, "## Examples")
      assert String.contains?(docs, "<Example>Test</Example>")
    end

    test "handles missing metadata sections" do
      # Minimal metadata
      metadata = %{
        description: "Minimal component"
      }

      docs = Definition.generate_docs(metadata)

      assert String.contains?(docs, "Minimal component")
      assert String.contains?(docs, "No attributes")
      assert String.contains?(docs, "No slots")
      assert String.contains?(docs, "No examples provided")
    end
  end

  describe "__using__ macro" do
    defmodule TestComponent do
      use Portfolio.Content.MarkdownRendering.Components.Definition,
        type: :test_component,
        function: :render_test,
        description: "A test component for testing",
        attributes: %{
          size: %{
            type: :string,
            required: true,
            description: "Size of component"
          }
        },
        slots: [
          %{
            name: :content,
            description: "Content slot"
          }
        ],
        examples: ["<TestComponent size=\"large\">Test</TestComponent>"]

      def render_test(assigns), do: "Test Component #{assigns.size}"
    end

    import ExUnit.CaptureLog

    test "implements behavior callbacks" do
      assert TestComponent.component_type() == :test_component
      assert TestComponent.component_function() == :render_test

      metadata = TestComponent.component_metadata()
      assert is_map(metadata)
      assert Map.has_key?(metadata, :attributes)
      assert Map.has_key?(metadata, :slots)
      assert Map.has_key?(metadata, :examples)
    end

    test "provides register function" do
      # Mock the Registry.register_component function
      expect = fn ->
        assert capture_log(fn ->
                 # We'll just assert that the register function exists and can be called
                 # without actually trying to call the real Registry
                 TestComponent.register()
               end) =~ "GenServer.call"
      end

      # If Registry is running, test will work normally
      # If Registry is not running, we'll still verify the function exists
      try do
        expect.()
      rescue
        _ -> expect.()
      end
    end
  end
end
