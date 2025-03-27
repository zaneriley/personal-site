defmodule Portfolio.Content.Markdown.Component.Definition do
  @moduledoc """
  Provides a macro (`use`) for defining Markdown pipeline-aware components.

  This module simplifies the process of creating Phoenix function components
  that can be discovered and used by the `Portfolio.Content.Markdown.Pipeline`.

  When a module `use`s this definition, it:
  1. Defines functions to access component metadata (type, function, attributes, etc.).
  2. **Automatically registers** the component with the `Portfolio.Content.Markdown.Component.Registry`
     via `Phoenix.PubSub`. This registration happens during module compilation
     (or runtime initialization if PubSub isn't ready at compile time), enabling
     discovery by the pipeline and supporting hot-reloading.

  Example Usage:

      defmodule MyComponent do
        use Portfolio.Content.Markdown.Component.Definition,
          type: :my_component,
          function: :render,
          attributes: %{size: %{type: :string, required: true}}

        def render(assigns) do
          ~H\"\"\"
          <div class={@size}>My Component</div>
          \"\"\"
        end
      end
  """

  require Logger

  @doc """
  A macro for defining markdown components with automatic registration.

  This macro:
  1. Processes the component metadata
  2. Generates registration functions
  3. Automatically registers the component via PubSub
  4. Handles hot reloading for development

  ## Options

  * `:type` - The component type identifier (required)
  * `:function` - The function to use for rendering (required)
  * `:description` - Human-readable description of the component
  * `:attributes` - Map of attribute specifications
  * `:examples` - List of usage examples
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @component_type Keyword.fetch!(opts, :type)
      @component_function Keyword.fetch!(opts, :function)
      @component_description Keyword.get(opts, :description, "")
      @component_attributes Keyword.get(opts, :attributes, %{})
      @component_examples Keyword.get(opts, :examples, [])

      # Register the component when the module is compiled
      @on_definition Portfolio.Content.Markdown.Component.Definition
      @before_compile Portfolio.Content.Markdown.Component.Definition
      @after_compile Portfolio.Content.Markdown.Component.Definition

      # Define component metadata accessors
      def component_type, do: @component_type
      def component_function, do: @component_function
      def component_description, do: @component_description
      def component_attributes, do: @component_attributes
      def component_examples, do: @component_examples

      # Provide a manual registration function for backwards compatibility
      def register do
        Portfolio.Content.Markdown.Component.Definition.register_component(
          __MODULE__,
          @component_type,
          @component_function
        )
      end
    end
  end

  @doc false
  # Triggered by @on_definition - could add validations here
  def __on_definition__(_env, _kind, _name, _args, _guards, _body) do
    # Could validate component structure here if needed
    :ok
  end

  @doc false
  # Triggered by @before_compile - add any compile-time code generation
  defmacro __before_compile__(_env) do
    quote do
      # Additional compile-time functionality can be added here
    end
  end

  @doc false
  # Triggered by @after_compile - register the component
  def __after_compile__(env, _bytecode) do
    try do
      module_name = env.module
      component_type = Module.get_attribute(module_name, :component_type)

      if component_type != nil do
        # Get the component function name, default to the component type name
        function_name =
          Module.get_attribute(module_name, :component_function) ||
            component_type

        register_component(module_name, component_type, function_name)
      end
    catch
      :error, %ArgumentError{} ->
        require Logger

        Logger.debug(
          "PubSub not available during compilation, component will register at runtime"
        )
    end
  end

  @doc """
  Registers a component with the registry via PubSub.

  This function broadcasts a registration message to the PubSub system,
  which is picked up by the component registry.

  ## Parameters

  * `module` - The component module
  * `type` - The component type identifier
  * `function` - The function to use for rendering
  """
  @pubsub_topic "component_registration"
  def register_component(module, type, function) do
    Logger.debug(
      "Registering component #{inspect(type)} from #{inspect(module)}"
    )

    # When PubSub is not available at compile time, this will raise an ArgumentError
    # which is caught by the __after_compile__ function
    if Code.ensure_loaded?(Phoenix.PubSub) and ensure_pubsub_started?() do
      Phoenix.PubSub.broadcast(
        Portfolio.PubSub,
        @pubsub_topic,
        {:register_component, type, {module, function}}
      )
    else
      Logger.debug(
        "PubSub not available for #{inspect(module)}. Registration will happen at runtime."
      )
    end

    :ok
  end

  # Check if PubSub is available and started
  defp ensure_pubsub_started? do
    case Application.started_applications() do
      apps when is_list(apps) ->
        Enum.any?(apps, fn {app, _, _} -> app == :phoenix_pubsub end)

      _ ->
        false
    end
  end
end
