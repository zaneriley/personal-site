defmodule Portfolio.Content.MarkdownRendering.Components.RegistryTest do
  use ExUnit.Case, async: false

  alias Portfolio.Content.MarkdownRendering.Components.{Registry, Definition}

  # Define a test component for use in registration tests
  defmodule TestComponent do
    use Definition

    def component_type, do: :test_component
    def component_function, do: :test_component

    def component_metadata do
      %{
        description: "Test component for registry tests",
        attributes: [
          %{name: :size, type: :string, required: true},
          %{name: :color, type: :string, default: "blue"}
        ],
        slots: [
          %{name: :default, description: "Main content"}
        ],
        examples: [
          %{
            description: "Basic example",
            code:
              "```\n<TestComponent size=\"large\">Content</TestComponent>\n```"
          }
        ]
      }
    end
  end

  setup do
    # Stop the registry if it's already running to ensure test isolation
    Registry.stop()
    # Start a fresh registry for each test
    {:ok, pid} = start_supervised(Registry)
    %{registry_pid: pid}
  end

  describe "component registration" do
    test "registers a component successfully" do
      assert :ok = Registry.register(:test_component, TestComponent)

      # Verify the component can be looked up
      assert {:ok, TestComponent} = Registry.lookup(:test_component)

      # Verify metadata can be retrieved
      assert {:ok, metadata} = Registry.get_metadata(:test_component)
      assert is_map(metadata)
      assert metadata.description == "Test component for registry tests"
    end

    test "handles registering the same component twice" do
      assert :ok = Registry.register(:test_component, TestComponent)
      assert :ok = Registry.register(:test_component, TestComponent)

      # Verify only one registration took effect
      assert {:ok, TestComponent} = Registry.lookup(:test_component)
    end

    test "fails when registering with a different module" do
      assert :ok = Registry.register(:test_component, TestComponent)

      # Try to register the same component type with a different module
      assert {:error, :already_registered_with_different_module} =
               Registry.register(:test_component, String)
    end
  end

  describe "component lookup" do
    test "handles lookup for non-existent component" do
      assert {:error, :not_found} = Registry.lookup(:non_existent)
    end

    test "lists all registered components" do
      # Register multiple components
      Registry.register(:test_component, TestComponent)
      Registry.register(:other_component, TestComponent)

      # Get the list of registered components
      components = Registry.list_components()

      assert is_list(components)
      assert length(components) >= 2
      assert :test_component in components
      assert :other_component in components
    end
  end

  describe "component unregistration" do
    test "unregisters components successfully" do
      # Register then unregister
      Registry.register(:test_component, TestComponent)
      assert :ok = Registry.unregister(:test_component)

      # Verify it's no longer available
      assert {:error, :not_found} = Registry.lookup(:test_component)
    end

    test "handles unregistering non-existent component" do
      assert :ok = Registry.unregister(:non_existent)
    end
  end

  describe "backward compatibility" do
    test "supports aliases for backward compatibility" do
      Registry.register(:test_component, TestComponent)

      # Check if we can look up using an alias
      Registry.register_alias(:legacy_name, :test_component)
      assert {:ok, TestComponent} = Registry.lookup(:legacy_name)

      # Unregistering the actual component should remove the alias too
      Registry.unregister(:test_component)
      assert {:error, :not_found} = Registry.lookup(:legacy_name)
    end
  end
end
