defmodule Portfolio.Content.MarkdownRendering.Pipeline.Stages.ComponentResolution do
  @moduledoc """
  Pipeline stage that resolves component references in the AST.

  This stage looks for component nodes in the AST and ensures they reference
  valid components from the component registry. It transforms the AST by
  validating component references and enriching them with metadata.
  """

  use Portfolio.Content.MarkdownRendering.Pipeline.Stage,
    name: "Component Resolution"

  alias Portfolio.Content.MarkdownRendering.AST
  alias Portfolio.Content.MarkdownRendering.Components.Registry
  require Logger

  @doc """
  Transforms the AST by resolving component references.

  This looks for component nodes in the AST and resolves them against the
  component registry. It validates that referenced components exist and
  adds metadata about the component's module and function.

  ## Options

  - `:ignore_missing` - When true, missing components are left as-is rather than causing an error
  """
  @impl true
  def transform(ast, opts) do
    ignore_missing = Keyword.get(opts, :ignore_missing, false)

    try do
      result = AST.map(ast, &resolve_component(&1, ignore_missing))
      {:ok, result}
    rescue
      e in RuntimeError ->
        {:error, e.message}

      e ->
        {:error, "Error resolving components: #{inspect(e)}"}
    end
  end

  # Resolves a component node against the registry
  defp resolve_component(
         {:component, type, attrs, content, meta} = node,
         ignore_missing
       ) do
    case Registry.lookup_component(type) do
      {:ok, {module, function}} ->
        # Component found, add module and function to metadata
        component_meta =
          Map.merge(meta, %{
            module: module,
            function: function,
            resolved: true
          })

        # Return the node with enhanced metadata
        {:component, type, attrs, content, component_meta}

      {:error, :component_not_found} ->
        if ignore_missing do
          # Just return the node unchanged if ignoring missing components
          Logger.warning("Component not found but ignoring: #{inspect(type)}")
          node
        else
          # Raise an error to be caught by the transform function
          raise "Unknown component type: #{inspect(type)}"
        end
    end
  end

  # Pass through non-component nodes
  defp resolve_component(node, _ignore_missing), do: node
end
