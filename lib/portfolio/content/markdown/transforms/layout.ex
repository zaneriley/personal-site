defmodule Portfolio.Content.Markdown.Transforms.Layout do
  @moduledoc """
  Transform for processing layout structures in the markdown AST.

  This transform examines metadata (usually from frontmatter) and applies
  appropriate layout components to wrap the content according to layout
  specifications.
  """

  @doc """
  Applies layout structures to the AST based on metadata.

  ## Parameters
    - ast: The AST to transform
    - opts: Options to control the transformation

  ## Options
    - `:metadata` - A map containing layout configuration (default: %{})

  ## Returns
    - {:ok, transformed_ast} on success
    - {:error, reason} on failure
  """
  @spec apply(list(), keyword()) :: {:ok, list()} | {:error, String.t()}
  def apply(ast, opts \\ []) do
    metadata = Keyword.get(opts, :metadata, %{})

    try do
      transformed_ast = process_layout(ast, metadata)
      {:ok, transformed_ast}
    rescue
      e ->
        {:error, "Error processing layout: #{inspect(e)}"}
    end
  end

  # Process the layout based on metadata
  defp process_layout(ast, metadata) do
    # Check if a layout is specified in metadata
    case Map.get(metadata, "layout") do
      "columns" ->
        # Apply column layout
        process_column_layout(ast, metadata)

      "grid" ->
        # Apply grid layout
        process_grid_layout(ast, metadata)

      nil ->
        # No layout specified, return AST unchanged
        ast

      unknown_layout ->
        # Unsupported layout type, warn and return AST unchanged
        require Logger
        Logger.warning("Unsupported layout type: #{inspect(unknown_layout)}")
        ast
    end
  end

  # Process column layout
  defp process_column_layout(ast, metadata) do
    # Extract column specifications from metadata
    columns =
      case Map.get(metadata, "columns") do
        col_specs when is_list(col_specs) -> col_specs
        _ -> []
      end

    if columns == [] do
      # No column specifications, return AST unchanged
      ast
    else
      # Create column layout component with the content
      [
        {:component, :column_layout, %{columns: format_columns(columns)}, ast,
         %{}}
      ]
    end
  end

  # Process grid layout nodes
  defp process_grid_layout(ast, _metadata) do
    # Extract grid specifications from metadata
    # This is a placeholder for future grid layout implementation
    require Logger
    Logger.info("Grid layout processing not fully implemented yet")

    # For now, just return the AST unchanged
    ast
  end

  # Format column specifications for the column_layout component
  defp format_columns(columns) do
    Enum.map(columns, fn col ->
      %{
        width: Map.get(col, "width", "1"),
        content: Map.get(col, "content", "main")
      }
    end)
  end
end
