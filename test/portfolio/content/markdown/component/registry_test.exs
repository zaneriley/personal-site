defmodule Portfolio.Content.Markdown.Component.RegistryTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  alias Portfolio.Content.Markdown.Component.Registry

  # Define a test component for use in registration tests
  defmodule TestComponent do
    def render(assigns) do
      # This is just a stub for testing
    end
  end

  defmodule AnotherComponent do
    def render(assigns) do
      # Another stub component
    end
  end

  setup do
    # Stop the registry if it's running to ensure test isolation
    if Process.whereis(Registry) do
      GenServer.stop(Registry)
    end

    # Start a fresh registry for each test
    {:ok, pid} = Registry.start_link()
    %{registry_pid: pid}
  end

  describe "register/2" do
    test "registers a component successfully" do
      component_type = :test_component
      assert :ok = Registry.register(component_type, TestComponent)

      # Verify the component can be looked up
      assert {:ok, {TestComponent, :render}} = Registry.lookup(component_type)
    end

    test "handles registering the same component twice" do
      component_type = :test_component
      assert :ok = Registry.register(component_type, TestComponent)
      assert :ok = Registry.register(component_type, TestComponent)

      # Verify only one registration took effect
      assert {:ok, {TestComponent, :render}} = Registry.lookup(component_type)
    end

    test "fails when registering with a different module" do
      component_type = :test_component
      assert :ok = Registry.register(component_type, TestComponent)

      # Try to register the same component type with a different module
      assert {:error, :already_registered} =
               Registry.register(component_type, AnotherComponent)
    end

    test "registers with custom function" do
      component_type = :test_component

      assert :ok =
               Registry.register(component_type, TestComponent,
                 custom_function: :custom
               )

      # Verify the component is registered with the custom function
      assert {:ok, {TestComponent, :custom}} = Registry.lookup(component_type)
    end
  end

  describe "lookup/1" do
    test "handles lookup for non-existent component" do
      assert {:error, :not_found} = Registry.lookup(:non_existent)
    end
  end

  describe "list/0" do
    test "lists all registered components" do
      # Register multiple components
      Registry.register(:test_component, TestComponent)
      Registry.register(:other_component, AnotherComponent)

      # Get the list of registered components
      components = Registry.list()

      assert is_list(components)
      assert length(components) == 2
      assert :test_component in components
      assert :other_component in components
    end

    test "returns empty list when no components are registered" do
      assert Registry.list() == []
    end
  end

  describe "unregister/1" do
    test "unregisters components successfully" do
      # Register then unregister
      component_type = :test_component
      Registry.register(component_type, TestComponent)
      assert :ok = Registry.unregister(component_type)

      # Verify it's no longer available
      assert {:error, :not_found} = Registry.lookup(component_type)
    end

    test "handles unregistering non-existent component" do
      assert :ok = Registry.unregister(:non_existent)
    end
  end
end
