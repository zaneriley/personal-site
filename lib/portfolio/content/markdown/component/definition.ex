defmodule Portfolio.Content.Markdown.Component.Definition do
  @moduledoc """
  Provides a macro (`use`) for defining Markdown pipeline-aware components.

  This module simplifies the process of creating Phoenix function components
  that can be discovered and used by the `Portfolio.Content.Markdown.Pipeline`.

  When a module `use`s this definition, it:
  1. Defines functions to access component metadata (type, function, attributes, etc.).
  2. **Automatically registers** the component with the
     `Portfolio.Content.Markdown.Component.Registry` via a synchronous
     `GenServer.call/3`. Registration runs from `__after_compile__/2`.
     If the registry is not running (e.g. during `mix compile` before the
     application supervision tree starts), registration is silently skipped
     and the component will register on its next compile inside a running
     system (hot-reload / runtime recompile).

  ## The pipeline calling convention

  When the renderer encounters a `{:component, type, attrs, children, _meta}`
  node, it applies the registered function with a SINGLE assigns map of the
  shape `%{component: type, attrs: attrs_map, content: rendered_children_html}`
  — NOT the per-attr assigns a HEEx caller would pass. Two consequences for
  component authors:

  1. The registered function needs a clause that accepts that shape and
     normalizes it (attr keys are STRINGS once content has round-tripped
     storage). See `PortfolioWeb.Components.CodeBlock.code_block/1` for the
     pattern.
  2. Return a `%Phoenix.LiveView.Rendered{}` (or any `Phoenix.HTML.Safe`) —
     the renderer converts the result to an HTML string itself.

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

  alias Portfolio.Content.Markdown.Component.Registry

  @doc """
  A macro for defining markdown components with automatic registration.

  This macro:
  1. Processes the component metadata
  2. Generates registration functions
  3. Automatically registers the component with the Registry
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
    module_name = env.module
    component_type = Module.get_attribute(module_name, :component_type)

    if component_type != nil do
      # Get the component function name, default to the component type name
      function_name =
        Module.get_attribute(module_name, :component_function) ||
          component_type

      register_component(module_name, component_type, function_name)
    end
  end

  @doc """
  Registers a component with the registry synchronously.

  Calls into the `Registry` GenServer's `handle_call({:register, ...}, ...)`
  clause. If the registry is not running (compile-time before app boot),
  the call would `:exit` — caught here and logged at debug level.

  ## Parameters

  * `module` - The component module
  * `type` - The component type identifier
  * `function` - The function to use for rendering
  """
  @spec register_component(module(), atom(), atom()) :: :ok
  def register_component(module, type, function) do
    Logger.debug(
      "Registering component #{inspect(type)} from #{inspect(module)}"
    )

    if Process.whereis(Registry) do
      try do
        _ = Registry.register(type, module, custom_function: function)
        :ok
      catch
        :exit, _reason ->
          Logger.debug(
            "Registry not reachable for #{inspect(module)}; will register at runtime."
          )

          :ok
      end
    else
      Logger.debug(
        "Registry not running for #{inspect(module)}; will register at runtime."
      )

      :ok
    end
  end
end
