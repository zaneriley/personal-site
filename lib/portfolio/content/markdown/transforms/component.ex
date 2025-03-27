defmodule Portfolio.Content.Markdown.Transforms.Component do
  @moduledoc """
  A pipeline stage for resolving and enriching component references in the Markdown AST.

  This transform operates on the AST provided by the `Portfolio.Content.Markdown.Pipeline`.
  It searches for nodes representing components, which can be:
  - Custom components parsed from `::component::` syntax (represented as `{:component, type, ...}`).
  - Standard elements designated to become components (e.g., transforming `{"img", ...}` to `{:component, :figure, ...}`).

  For each component node found, it uses the `Portfolio.Content.Markdown.Component.Registry`
  to look up the component `type`. If found, it enriches the node's metadata with
  information about the implementing module and function.

  It handles cases where components might be missing from the registry, either by
  raising an error or logging a warning based on the `ignore_missing` option.
  """

  require Logger
  alias Portfolio.Content.Markdown.Component.Registry

  @doc """
  Resolves component references in the AST by checking them against a component registry.

  ## Parameters

  - `ast` - The AST to transform
  - `opts` - Options for the transformation

  ## Options

  - `:registry_fn` - Function that takes a component name and returns component info or nil (optional)
  - `:registry` - Module that implements lookup/1 function (defaults to Registry)
  - `:ignore_missing` - If true, missing components will be kept but logged (default: false)

  ## Returns

  - `{:ok, transformed_ast}` - Successfully transformed AST
  - `{:error, reason}` - Error during transformation
  """
  @spec apply(list(), keyword()) :: {:ok, list()} | {:error, String.t()}
  def apply(ast, opts \\ []) do
    # Get the registry lookup function
    registry_fn = get_registry_fn(opts)
    ignore_missing = Keyword.get(opts, :ignore_missing, false)

    try do
      {:ok, transform_ast(ast, registry_fn, ignore_missing)}
    rescue
      e in RuntimeError ->
        {:error, e.message}

      e ->
        {:error, "Error resolving components: #{inspect(e)}"}
    end
  end

  # Get the registry lookup function - either from options or use Registry module
  defp get_registry_fn(opts) do
    case Keyword.get(opts, :registry_fn) do
      nil ->
        # Use the Registry module by default
        registry_module = Keyword.get(opts, :registry, Registry)

        fn component_type ->
          case registry_module.lookup(to_atom(component_type)) do
            {:ok, {module, function}} ->
              {:ok, %{module: module, function: function}}

            {:error, :not_found} ->
              nil
          end
        end

      registry_fn when is_function(registry_fn, 1) ->
        registry_fn
    end
  end

  # Convert string to atom safely (only for component names that should be limited)
  defp to_atom(name) when is_atom(name), do: name
  defp to_atom(name) when is_binary(name), do: String.to_atom(name)

  # Recursively transform the AST
  defp transform_ast(ast, registry_fn, ignore_missing) when is_list(ast) do
    Enum.map(ast, &resolve_node(&1, registry_fn, ignore_missing))
  end

  # Resolve component nodes
  defp resolve_node(
         {:component, type, attrs, content, meta},
         registry_fn,
         ignore_missing
       ) do
    case registry_fn.(type) do
      {:ok, component_info} ->
        # Component found, enrich the metadata
        {:component, type, attrs,
         transform_ast(content, registry_fn, ignore_missing),
         Map.merge(meta, component_info)}

      nil ->
        # Component not found, handle based on ignore_missing
        if ignore_missing do
          Logger.warning(
            "Component '#{type}' not found, but ignore_missing is true"
          )

          {:component, type, attrs,
           transform_ast(content, registry_fn, ignore_missing), meta}
        else
          # Raise error to be caught in apply/2
          raise "Component '#{type}' not found in registry"
        end
    end
  end

  # Handle image nodes specifically (HTML img tag)
  defp resolve_node(
         {"img", attrs, content, meta},
         registry_fn,
         ignore_missing
       ) do
    # Convert to :image component
    resolve_node(
      {:component, :image, attrs, content, meta},
      registry_fn,
      ignore_missing
    )
  end

  # Typography nodes are passed through without registry lookup
  defp resolve_node(
         {:typography, tag, attrs, content, meta},
         registry_fn,
         ignore_missing
       ) do
    {:typography, tag, attrs,
     transform_ast(content, registry_fn, ignore_missing), meta}
  end

  # Element nodes (HTML) - process content recursively
  defp resolve_node(
         {:element, tag, attrs, content, meta},
         registry_fn,
         ignore_missing
       ) do
    {:element, tag, attrs, transform_ast(content, registry_fn, ignore_missing),
     meta}
  end

  # Pass through any other node type
  defp resolve_node(node, _registry_fn, _ignore_missing), do: node
end
