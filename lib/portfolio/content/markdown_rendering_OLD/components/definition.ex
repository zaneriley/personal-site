defmodule Portfolio.Content.MarkdownRendering.Components.Definition do
  @moduledoc """
  Defines contracts and behaviors for components used in markdown rendering.

  This module provides tools for defining, validating, and documenting components
  that can be used in markdown content. It helps ensure that components adhere
  to consistent patterns and can be properly integrated into the rendering system.
  """

  alias Portfolio.Content.MarkdownRendering.Components.Registry

  @doc """
  A behaviour to be implemented by markdown components.

  Components that implement this behaviour can be registered with the component
  registry and used in markdown content.
  """
  @callback component_type() :: atom()
  @callback component_function() :: atom()
  @callback component_metadata() :: Registry.component_metadata()

  @doc """
  Validates attributes against component specifications.

  ## Parameters

  - `attrs` - Map of attributes to validate
  - `specs` - Map of attribute specifications

  ## Examples

      iex> specs = %{
      ...>   size: %{type: :string, required: true},
      ...>   color: %{type: :string, required: false, default: "black"}
      ...> }
      iex> Definition.validate_attributes(%{size: "large"}, specs)
      {:ok, %{size: "large", color: "black"}}

      iex> Definition.validate_attributes(%{}, specs)
      {:error, "Missing required attribute: size"}
  """
  @spec validate_attributes(map(), %{atom() => Registry.attribute_spec()}) ::
          {:ok, map()} | {:error, String.t()}
  def validate_attributes(attrs, specs) do
    # Apply defaults first
    attrs_with_defaults = apply_defaults(attrs, specs)

    # Then validate required attributes and types
    with :ok <- validate_required_attributes(attrs_with_defaults, specs) do
      validate_attribute_types(attrs_with_defaults, specs)
    end
  end

  # Apply default values for missing attributes
  defp apply_defaults(attrs, specs) do
    Enum.reduce(specs, attrs, fn {attr_name, spec}, acc ->
      if Map.has_key?(acc, attr_name) do
        acc
      else
        case Map.get(spec, :default) do
          nil -> acc
          default -> Map.put(acc, attr_name, default)
        end
      end
    end)
  end

  # Validate that all required attributes are present
  defp validate_required_attributes(attrs, specs) do
    missing =
      for {attr_name, spec} <- specs,
          Map.get(spec, :required, false),
          not Map.has_key?(attrs, attr_name),
          do: attr_name

    case missing do
      [] -> :ok
      [attr | _] -> {:error, "Missing required attribute: #{attr}"}
    end
  end

  # Validate attribute types
  defp validate_attribute_types(attrs, specs) do
    result =
      Enum.reduce_while(attrs, attrs, fn {attr_name, value}, acc ->
        case Map.get(specs, attr_name) do
          nil ->
            # Attribute not in spec, just pass it through
            {:cont, acc}

          spec ->
            # Validate type if specified
            case validate_type(value, Map.get(spec, :type)) do
              :ok ->
                {:cont, acc}

              {:error, reason} ->
                {:halt, {:error, "#{reason} for attribute #{attr_name}"}}
            end
        end
      end)

    case result do
      {:error, reason} -> {:error, reason}
      validated_attrs -> {:ok, validated_attrs}
    end
  end

  # Type validation for attribute values
  defp validate_type(_value, nil), do: :ok

  defp validate_type(value, types) when is_list(types) do
    if Enum.any?(types, &(validate_type(value, &1) == :ok)) do
      :ok
    else
      {:error,
       "Value does not match any of the allowed types: #{inspect(types)}"}
    end
  end

  defp validate_type(value, :string) when is_binary(value), do: :ok
  defp validate_type(value, :integer) when is_integer(value), do: :ok
  defp validate_type(value, :float) when is_float(value), do: :ok
  defp validate_type(value, :number) when is_number(value), do: :ok
  defp validate_type(value, :boolean) when is_boolean(value), do: :ok
  defp validate_type(value, :list) when is_list(value), do: :ok
  defp validate_type(value, :map) when is_map(value), do: :ok
  defp validate_type(value, :atom) when is_atom(value), do: :ok

  defp validate_type(_value, type) do
    {:error, "Value does not match type #{inspect(type)}"}
  end

  @doc """
  Creates component documentation from metadata.

  ## Parameters

  - `metadata` - Component metadata

  ## Examples

      iex> metadata = %{
      ...>   description: "A simple component",
      ...>   attributes: %{
      ...>     size: %{type: :string, required: true, description: "Size of component"}
      ...>   }
      ...> }
      iex> docs = Definition.generate_docs(metadata)
      iex> String.contains?(docs, "A simple component")
      true
  """
  @spec generate_docs(Registry.component_metadata()) :: String.t()
  def generate_docs(metadata) do
    description = Map.get(metadata, :description, "No description provided")

    attributes_docs =
      case Map.get(metadata, :attributes) do
        nil -> "No attributes"
        attrs -> generate_attributes_docs(attrs)
      end

    slots_docs =
      case Map.get(metadata, :slots) do
        nil -> "No slots"
        slots -> generate_slots_docs(slots)
      end

    examples =
      case Map.get(metadata, :examples) do
        nil -> "No examples provided"
        examples -> generate_examples_docs(examples)
      end

    """
    ## Description

    #{description}

    ## Attributes

    #{attributes_docs}

    ## Slots

    #{slots_docs}

    ## Examples

    #{examples}
    """
  end

  # Generate documentation for attributes
  defp generate_attributes_docs(attrs) do
    Enum.map_join(attrs, "\n", fn {name, spec} ->
      type = Map.get(spec, :type, "any")

      required =
        if Map.get(spec, :required, false), do: "Required", else: "Optional"

      default = Map.get(spec, :default, "none")
      description = Map.get(spec, :description, "No description")

      "- `#{name}` (#{type}, #{required}, Default: #{inspect(default)}): #{description}"
    end)
  end

  # Generate documentation for slots
  defp generate_slots_docs(slots) do
    Enum.map_join(slots, "\n", fn slot ->
      name = Map.get(slot, :name, "unnamed")
      description = Map.get(slot, :description, "No description")

      attributes =
        case Map.get(slot, :attributes) do
          nil ->
            ""

          attrs ->
            attrs_docs = generate_attributes_docs(attrs)

            """

            Attributes:
            #{attrs_docs}
            """
        end

      "- `#{name}`: #{description}#{attributes}"
    end)
  end

  # Generate documentation for examples
  defp generate_examples_docs(examples) do
    Enum.map_join(examples, "\n", fn example ->
      """
      ```
      #{example}
      ```
      """
    end)
  end

  @doc """
  A macro to simplify creation of component modules.

  This macro implements the Component behaviour and provides common functionality,
  allowing you to focus on the component definition.

  ## Example

      defmodule MyComponent do
        use Portfolio.Content.MarkdownRendering.Components.Definition,
          type: :my_component,
          function: :my_component,
          description: "A simple component",
          attributes: %{
            size: %{type: :string, required: true, description: "Size of component"}
          }

        use Phoenix.Component

        attr :size, :string, required: true

        def my_component(assigns) do
          assigns = assign(assigns, :class, "my-component-" <> assigns.size)
          ~H\"\"\"
          <div class={@class}>My Component</div>
          \"\"\"
        end
      end
  """
  defmacro __using__(opts) do
    quote location: :keep do
      @behaviour Portfolio.Content.MarkdownRendering.Components.Definition

      @component_type unquote(opts[:type]) ||
                        __MODULE__
                        |> Module.split()
                        |> List.last()
                        |> Phoenix.Naming.underscore()
                        |> String.to_atom()
      @component_function unquote(opts[:function]) || @component_type
      @component_description unquote(opts[:description]) ||
                               "No description provided"
      @component_attributes unquote(Macro.escape(opts[:attributes] || %{}))
      @component_slots unquote(Macro.escape(opts[:slots] || []))
      @component_examples unquote(Macro.escape(opts[:examples] || []))

      @impl true
      def component_type, do: @component_type

      @impl true
      def component_function, do: @component_function

      @impl true
      def component_metadata do
        %{
          description: @component_description,
          attributes: @component_attributes,
          slots: @component_slots,
          examples: @component_examples
        }
      end

      @doc """
      Registers this component with the component registry.
      """
      def register do
        Portfolio.Content.MarkdownRendering.Components.Registry.register_component(
          component_type(),
          __MODULE__,
          component_function(),
          component_metadata()
        )
      end

      # Allow overriding the default implementations
      defoverridable component_type: 0,
                     component_function: 0,
                     component_metadata: 0
    end
  end
end
