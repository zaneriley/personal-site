defmodule Portfolio.Content.Markdown.Component.RegistryTest do
  use ExUnit.Case, async: false

  alias Portfolio.Content.Markdown.Component.Registry

  # Define a test component for use in registration tests
  defmodule TestComponent do
    def render(_assigns) do
      # This is just a stub for testing
    end
  end

  defmodule AnotherComponent do
    def render(_assigns) do
      # Another stub component
    end
  end

  setup do
    # Ensure the application is started
    Application.ensure_all_started(:portfolio)

    # Clear the registry state before each test
    Registry.clear_all_components()

    :ok
  end

  describe "Registry API - using global registry" do
    test "registers a component successfully" do
      component_type = :test_component_api
      Registry.register(component_type, TestComponent)

      # Verify the component can be looked up
      assert {:ok, {TestComponent, :render}} = Registry.lookup(component_type)

      # Cleanup
      Registry.unregister(component_type)
    end

    test "handles registering the same component twice" do
      component_type = :test_component_duplicate
      Registry.register(component_type, TestComponent)
      Registry.register(component_type, TestComponent)

      # Verify only one registration took effect
      assert {:ok, {TestComponent, :render}} = Registry.lookup(component_type)

      # Cleanup after the test
      Registry.unregister(component_type)
    end

    test "registers with custom function" do
      component_type = :test_component_custom
      Registry.register(component_type, TestComponent, custom_function: :custom)

      # Verify the component is registered with the custom function
      assert {:ok, {TestComponent, :custom}} = Registry.lookup(component_type)

      # Cleanup after the test
      Registry.unregister(component_type)
    end

    test "handles lookup for non-existent component" do
      assert {:error, :not_found} =
               Registry.lookup(:non_existent_test_component)
    end

    test "unregisters components successfully" do
      # Register then unregister
      component_type = :test_component_unregister
      Registry.register(component_type, TestComponent)
      assert :ok = Registry.unregister(component_type)

      # Verify it's no longer available
      assert {:error, :not_found} = Registry.lookup(component_type)
    end

    test "handles unregistering non-existent component" do
      assert :ok = Registry.unregister(:non_existent_test_component)
    end
  end

  describe "synchronous registration" do
    test "registry stores a component immediately after register/3 returns" do
      assert :ok = Registry.register(:sync_test, TestComponent)
      assert {:ok, {TestComponent, :render}} = Registry.lookup(:sync_test)

      Registry.unregister(:sync_test)
    end

    test "registry updates an existing registration on second call" do
      assert :ok = Registry.register(:update_test, TestComponent)
      assert {:ok, {TestComponent, :render}} = Registry.lookup(:update_test)

      assert :ok =
               Registry.register(:update_test, TestComponent,
                 custom_function: :custom
               )

      assert {:ok, {TestComponent, :custom}} = Registry.lookup(:update_test)

      Registry.unregister(:update_test)
    end

    test "multiple components can register in sequence" do
      components = [
        {:component_a, TestComponent, :render},
        {:component_b, AnotherComponent, :render},
        {:component_c, TestComponent, :custom}
      ]

      for {type, module, function} <- components do
        assert :ok =
                 Registry.register(type, module, custom_function: function)
      end

      for {type, module, function} <- components do
        assert {:ok, {^module, ^function}} = Registry.lookup(type)

        Registry.unregister(type)
      end
    end

    test "registry allows same component type to be replaced by same module" do
      component_type = :replaceable_component

      assert :ok =
               Registry.register(component_type, TestComponent,
                 custom_function: :initial
               )

      assert {:ok, {TestComponent, :initial}} =
               Registry.lookup(component_type)

      assert :ok =
               Registry.register(component_type, TestComponent,
                 custom_function: :updated
               )

      assert {:ok, {TestComponent, :updated}} =
               Registry.lookup(component_type)

      Registry.unregister(component_type)
    end

    test "registry allows component replacement from different module" do
      component_type = :different_module_component

      assert :ok = Registry.register(component_type, TestComponent)

      assert {:ok, {TestComponent, :render}} =
               Registry.lookup(component_type)

      assert :ok = Registry.register(component_type, AnotherComponent)

      assert {:ok, {AnotherComponent, :render}} =
               Registry.lookup(component_type)

      Registry.unregister(component_type)
    end
  end

  describe "Registry startup" do
    test "registry is responsive after startup and accepts registrations" do
      Registry.clear_all_components()

      assert :ok = Registry.register(:startup_test, TestComponent)

      assert {:ok, {TestComponent, :render}} =
               Registry.lookup(:startup_test)

      Registry.unregister(:startup_test)
    end
  end

  describe "Component self-registration" do
    test "component automatically registers itself when using Definition" do
      # Dynamic component creation with Definition
      module_name =
        :"Elixir.TestSelfRegisteringComponent#{System.unique_integer([:positive])}"

      module_definition =
        quote do
          defmodule unquote(module_name) do
            # Use our new Definition module
            use Portfolio.Content.Markdown.Component.Definition,
              type: :self_registering_test,
              function: :render,
              description: "Test self-registering component"

            def render(_assigns) do
              # Test component implementation
            end
          end
        end

      # Define the module — registration runs synchronously inside
      # __after_compile__, so the registry is updated before this returns.
      Code.eval_quoted(module_definition)

      # Verify the component was registered
      assert {:ok, {^module_name, :render}} =
               Registry.lookup(:self_registering_test)

      # Cleanup
      Registry.unregister(:self_registering_test)
    end

    test "component re-registers itself during hot code reloading" do
      # This test simulates hot code reloading by registering the same component type
      # with a different module implementation

      # First component implementation
      first_module_name =
        :"Elixir.HotReloadComponent#{System.unique_integer([:positive])}"

      first_module_definition =
        quote do
          defmodule unquote(first_module_name) do
            # Use our new Definition module
            use Portfolio.Content.Markdown.Component.Definition,
              type: :hot_reload_test,
              function: :render,
              description: "Original implementation"

            def render(_assigns) do
              "Original implementation"
            end
          end
        end

      # Define first implementation
      Code.eval_quoted(first_module_definition)

      # Verify first registration
      {:ok, {first_registered_module, :render}} =
        Registry.lookup(:hot_reload_test)

      assert first_registered_module == first_module_name

      # Second component implementation (simulating code reload)
      second_module_name =
        :"Elixir.HotReloadComponent#{System.unique_integer([:positive])}"

      second_module_definition =
        quote do
          defmodule unquote(second_module_name) do
            # Use our new Definition module
            use Portfolio.Content.Markdown.Component.Definition,
              type: :hot_reload_test,
              function: :render,
              description: "Updated implementation"

            def render(_assigns) do
              "Updated implementation"
            end
          end
        end

      # Define second implementation
      Code.eval_quoted(second_module_definition)

      # Verify component was re-registered with the new implementation
      {:ok, {second_registered_module, :render}} =
        Registry.lookup(:hot_reload_test)

      assert second_registered_module == second_module_name
      assert second_registered_module != first_registered_module

      # Cleanup
      Registry.unregister(:hot_reload_test)
    end

    test "components register synchronously on compile via Definition" do
      # This test simulates a component registering itself during compilation.
      # With synchronous registration the assertion can run immediately after
      # Code.eval_quoted/1 returns — no sleep or async waiting needed.

      module_name =
        :"Elixir.CompileTimeComponent#{System.unique_integer([:positive])}"

      module_code =
        quote do
          defmodule unquote(module_name) do
            use Portfolio.Content.Markdown.Component.Definition,
              type: :compile_time_test,
              function: :render,
              description: "Compile-time registration test"

            def render(_assigns) do
              # Dummy implementation
            end
          end
        end

      Code.eval_quoted(module_code)

      assert {:ok, {^module_name, :render}} =
               Registry.lookup(:compile_time_test)

      Registry.unregister(:compile_time_test)
    end
  end
end
