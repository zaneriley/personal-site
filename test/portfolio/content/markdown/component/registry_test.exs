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

  describe "PubSub registration" do
    test "registry receives component registration via PubSub" do
      # Directly publish a registration message to PubSub
      Phoenix.PubSub.broadcast(
        Portfolio.PubSub,
        "component_registration",
        {:register_component, :pubsub_test, {TestComponent, :render}}
      )

      # Allow time for message processing
      Process.sleep(50)

      # Verify the component was registered via PubSub
      assert {:ok, {TestComponent, :render}} = Registry.lookup(:pubsub_test)

      # Cleanup
      Registry.unregister(:pubsub_test)
    end

    test "registry receives updated component registrations" do
      # Register component
      Phoenix.PubSub.broadcast(
        Portfolio.PubSub,
        "component_registration",
        {:register_component, :update_test, {TestComponent, :render}}
      )

      Process.sleep(50)
      assert {:ok, {TestComponent, :render}} = Registry.lookup(:update_test)

      # Update component with different function
      Phoenix.PubSub.broadcast(
        Portfolio.PubSub,
        "component_registration",
        {:register_component, :update_test, {TestComponent, :custom}}
      )

      Process.sleep(50)
      assert {:ok, {TestComponent, :custom}} = Registry.lookup(:update_test)

      # Cleanup
      Registry.unregister(:update_test)
    end

    # New test case for multiple components registering in sequence
    test "multiple components can register via PubSub in sequence" do
      # Register several components in sequence
      components = [
        {:component_a, TestComponent, :render},
        {:component_b, AnotherComponent, :render},
        {:component_c, TestComponent, :custom}
      ]

      for {type, module, function} <- components do
        Phoenix.PubSub.broadcast(
          Portfolio.PubSub,
          "component_registration",
          {:register_component, type, {module, function}}
        )

        # Small delay between registrations
        Process.sleep(10)
      end

      # Allow time for all messages to be processed
      Process.sleep(50)

      # Verify all components were registered
      for {type, module, function} <- components do
        assert {:ok, {^module, ^function}} = Registry.lookup(type)

        # Cleanup
        Registry.unregister(type)
      end
    end

    # New test case for handling component replacement from same module
    test "registry allows same component type to be replaced by same module" do
      # Define a test component type
      component_type = :replaceable_component

      # Register with initial function
      Phoenix.PubSub.broadcast(
        Portfolio.PubSub,
        "component_registration",
        {:register_component, component_type, {TestComponent, :initial}}
      )

      Process.sleep(50)
      assert {:ok, {TestComponent, :initial}} = Registry.lookup(component_type)

      # Register same type with different function but same module
      Phoenix.PubSub.broadcast(
        Portfolio.PubSub,
        "component_registration",
        {:register_component, component_type, {TestComponent, :updated}}
      )

      Process.sleep(50)
      assert {:ok, {TestComponent, :updated}} = Registry.lookup(component_type)

      # Cleanup
      Registry.unregister(component_type)
    end

    # New test case for handling component replacement from different module
    test "registry allows component replacement from different module" do
      # Define a test component type
      component_type = :different_module_component

      # Register with initial module
      Phoenix.PubSub.broadcast(
        Portfolio.PubSub,
        "component_registration",
        {:register_component, component_type, {TestComponent, :render}}
      )

      Process.sleep(50)
      assert {:ok, {TestComponent, :render}} = Registry.lookup(component_type)

      # Register same type with different module
      Phoenix.PubSub.broadcast(
        Portfolio.PubSub,
        "component_registration",
        {:register_component, component_type, {AnotherComponent, :render}}
      )

      Process.sleep(50)

      assert {:ok, {AnotherComponent, :render}} =
               Registry.lookup(component_type)

      # Cleanup
      Registry.unregister(component_type)
    end
  end

  describe "Registry startup" do
    test "registry subscribes to PubSub on startup" do
      # Since we're using the global registry, we'll test by clearing it
      # and then sending a PubSub message to verify it's subscribed
      Registry.clear_all_components()

      # Broadcast a registration message
      Phoenix.PubSub.broadcast(
        Portfolio.PubSub,
        "component_registration",
        {:register_component, :startup_test, {TestComponent, :render}}
      )

      # Allow time for message processing
      Process.sleep(50)

      # Verify the component was registered
      assert {:ok, {TestComponent, :render}} = Registry.lookup(:startup_test)

      # Cleanup
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

      # Define the module
      Code.eval_quoted(module_definition)

      # No need to manually call register - it should happen automatically
      # But we'll sleep to allow time for any async registration
      Process.sleep(50)

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
      Process.sleep(50)

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
      Process.sleep(50)

      # Verify component was re-registered with the new implementation
      {:ok, {second_registered_module, :render}} =
        Registry.lookup(:hot_reload_test)

      assert second_registered_module == second_module_name
      assert second_registered_module != first_registered_module

      # Cleanup
      Registry.unregister(:hot_reload_test)
    end

    test "components can register at compile time through PubSub" do
      # This test simulates a component registering itself during compilation

      # Create a dynamic module that will broadcast registration on module compilation
      module_name =
        :"Elixir.CompileTimeComponent#{System.unique_integer([:positive])}"

      # Define the module with compile-time registration
      module_code =
        quote do
          defmodule unquote(module_name) do
            # Simulate __on_definition__ callback that will be in the Definition module
            @on_define Phoenix.PubSub.broadcast(
                         Portfolio.PubSub,
                         "component_registration",
                         {:register_component, :compile_time_test,
                          {__MODULE__, :render}}
                       )

            # This would be evaluated at compile time via a macro
            Code.eval_quoted(@on_define)

            def render(_assigns) do
              # Dummy implementation
            end
          end
        end

      # Evaluate the module definition
      Code.eval_quoted(module_code)

      # Allow time for registration to propagate
      Process.sleep(50)

      # Verify the component was registered
      assert {:ok, {^module_name, :render}} =
               Registry.lookup(:compile_time_test)

      # Cleanup
      Registry.unregister(:compile_time_test)
    end
  end
end
