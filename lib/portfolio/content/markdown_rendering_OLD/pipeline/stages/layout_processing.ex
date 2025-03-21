defmodule Portfolio.Content.MarkdownRendering.Pipeline.Stages.LayoutProcessing do
  @moduledoc """
  Pipeline stage that handles layout settings from frontmatter.

  This stage looks for layout specifications in the AST metadata (from frontmatter)
  and applies the specified layout to the content. It transforms the AST by wrapping
  content in layout components as specified.
  """

  use Portfolio.Content.MarkdownRendering.Pipeline.Stage,
    name: "Layout Processing"

  require Logger
  alias Portfolio.Content.MarkdownRendering.AST

  @doc """
  Transforms the AST by processing layout specifications.

  This looks at the metadata in the AST for layout specifications and applies
  the appropriate layout transformations, such as wrapping content in column layouts.
  """
  @impl true
  def transform(ast, opts) do
    # Ensure we have a proper map for metadata
    metadata =
      case Keyword.get(opts, :metadata) do
        nil ->
          %{}

        meta when is_map(meta) ->
          meta

        meta when is_list(meta) ->
          Enum.into(meta, %{})

        meta when is_binary(meta) ->
          # If we somehow got a string, try parsing it as YAML
          try do
            case :yamerl_constr.string(meta) do
              [parsed] ->
                # Convert parsed YAML to Elixir map with string keys
                Enum.into(parsed, %{}, fn
                  {k, v} when is_list(k) -> {List.to_string(k), v}
                  {k, v} -> {to_string(k), v}
                end)

              _ ->
                %{}
            end
          rescue
            _ ->
              Logger.warning(
                "Could not parse metadata string as YAML: #{inspect(meta)}"
              )

              %{}
          end

        unknown_meta ->
          Logger.warning("Invalid metadata format: #{inspect(unknown_meta)}")
          %{}
      end

    # Debug output
    Logger.debug("Processing layout with metadata: #{inspect(metadata)}")

    # Look for layout specifications in metadata
    case get_layout_spec(metadata) do
      {:column_layout, columns} ->
        Logger.debug("Found column layout specification: #{inspect(columns)}")
        # Wrap the content in a column layout component
        processed_ast = wrap_in_column_layout(ast, columns)
        {:ok, processed_ast}

      nil ->
        Logger.debug("No layout specification found")
        # No layout specified, just pass through the AST
        {:ok, ast}

      {:error, reason} ->
        # Error in layout specification
        Logger.warning("Error in layout specification: #{reason}")
        {:error, "Invalid layout specification: #{reason}"}
    end
  end

  # Get layout specification from metadata
  defp get_layout_spec(metadata) do
    case Map.get(metadata, "layout") do
      "columns" ->
        # Column layout specified, get column specifications
        columns = Map.get(metadata, "columns", [])

        Logger.debug(
          "Processing columns layout with columns: #{inspect(columns)}"
        )

        if is_list(columns) do
          {:column_layout, columns}
        else
          {:error, "Invalid column specification"}
        end

      _ ->
        Logger.debug("No specific layout found in: #{inspect(metadata)}")
        nil
    end
  end

  # Wrap content in a column layout component
  defp wrap_in_column_layout(ast, columns) do
    # Create a column layout component node that wraps the content
    [
      {:component, :column_layout, %{columns: columns}, ast, %{}}
    ]
  end
end
