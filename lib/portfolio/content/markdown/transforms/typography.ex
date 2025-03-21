defmodule Portfolio.Content.Markdown.Transforms.Typography do
  @moduledoc """
  Transform for enhancing typography elements in the markdown AST.

  This transform converts standard HTML tags like headings and paragraphs
  into typography component references with appropriate styling attributes.
  """

  @doc """
  Applies typography enhancements to the AST.

  ## Parameters
    - ast: The AST to transform
    - opts: Options to control the transformation

  ## Options
    - `:first_paragraph_dropcap` - When true, applies dropcap styling to the first paragraph (default: true)
    - `:heading_sizes` - Map of heading tags to size attributes (provides default sizes if not specified)
    - `:default_font` - Default font for typography elements (default: nil)
    - `:headings_font` - Font to use for headings (default: "cardinal")

  ## Returns
    - {:ok, transformed_ast} on success
    - {:error, reason} on failure
  """
  @spec apply(list(), keyword()) :: {:ok, list()} | {:error, String.t()}
  def apply(ast, opts \\ []) do
    options = build_options(opts)

    try do
      # State to track processing state (e.g., if we've found the first paragraph)
      initial_state = %{
        first_paragraph_found: false
      }

      {transformed_ast, _final_state} =
        process_nodes(ast, options, initial_state)

      {:ok, transformed_ast}
    rescue
      e ->
        {:error, "Error enhancing typography: #{inspect(e)}"}
    end
  end

  # Default options for typography enhancement
  defp build_options(opts) do
    defaults = %{
      first_paragraph_dropcap: true,
      heading_sizes: %{
        "h1" => "4xl",
        "h2" => "3xl",
        "h3" => "2xl",
        "h4" => "xl",
        "h5" => "lg",
        "h6" => "md"
      },
      default_font: nil,
      headings_font: "cardinal"
    }

    # Convert keyword options to map and merge with defaults
    opts_map = Map.new(opts)
    Map.merge(defaults, opts_map)
  end

  # Process a list of nodes with state tracking
  defp process_nodes(nodes, options, state) when is_list(nodes) do
    Enum.map_reduce(nodes, state, fn node, acc_state ->
      process_node(node, options, acc_state)
    end)
  end

  # Process heading nodes (h1-h6)
  defp process_node({"h" <> level, attrs, content, meta}, options, state) when level in ["1", "2", "3", "4", "5", "6"] do
    attrs_map = attrs_to_map(attrs)

    # Convert level to integer for sizing logic
    _level_int = String.to_integer(level)

    # Determine size based on heading level
    size = case level do
      "1" -> "4xl"
      "2" -> "3xl"
      "3" -> "2xl"
      "4" -> "xl"
      "5" -> "lg"
      "6" -> "md"
    end

    # Add font for headings if configured
    attrs_map = Map.put(attrs_map, :size, size)

    # Add default font if configured
    attrs_map =
      if options.default_font do
        Map.put(attrs_map, :font, options.default_font)
      else
        attrs_map
      end

    # Process content recursively
    {processed_content, new_state} = process_nodes(content, options, state)

    typography_node =
      create_typography_node("h" <> level, attrs_map, processed_content, meta)

    {typography_node, new_state}
  end

  # Process paragraph nodes
  defp process_node({"p", attrs, content, meta}, options, state) do
    attrs_map = attrs_to_map(attrs)

    # Check if this is the first paragraph and dropcap is enabled
    {is_dropcap, new_state} =
      if options.first_paragraph_dropcap and not state.first_paragraph_found do
        {true, %{state | first_paragraph_found: true}}
      else
        {false, state}
      end

    # Add dropcap attribute if needed
    attrs_map =
      if is_dropcap do
        Map.put(attrs_map, :dropcap, true)
      else
        attrs_map
      end

    # Add default size for paragraphs
    attrs_map = Map.put(attrs_map, :size, "md")

    # Add default font if configured
    attrs_map =
      if options.default_font do
        Map.put(attrs_map, :font, options.default_font)
      else
        attrs_map
      end

    # Process content recursively
    {processed_content, newer_state} =
      process_nodes(content, options, new_state)

    typography_node =
      create_typography_node("p", attrs_map, processed_content, meta)

    {typography_node, newer_state}
  end

  # Handle component nodes by recursively processing their content
  defp process_node({:component, type, attrs, content, meta}, options, state) do
    # Process content recursively
    {processed_content, new_state} = process_nodes(content, options, state)

    # Return component with processed content
    {{:component, type, attrs, processed_content, meta}, new_state}
  end

  # Process other element nodes by recursively processing their content
  defp process_node({tag, attrs, content, meta}, options, state) do
    # Process content recursively
    {processed_content, new_state} = process_nodes(content, options, state)

    # Return element with processed content
    {{tag, attrs, processed_content, meta}, new_state}
  end

  # Pass through text nodes unchanged
  defp process_node(text, _options, state) when is_binary(text) do
    {text, state}
  end

  # Catch-all for other node types
  defp process_node(node, _options, state) do
    {node, state}
  end

  # Helper function to create a typography component node
  defp create_typography_node(tag, attrs, content, meta) do
    {:typography, tag, attrs, content, meta}
  end

  # Convert attrs from list to map if needed
  defp attrs_to_map(attrs) when is_list(attrs) do
    Enum.into(attrs, %{})
  end

  defp attrs_to_map(attrs) when is_map(attrs) do
    attrs
  end
end
