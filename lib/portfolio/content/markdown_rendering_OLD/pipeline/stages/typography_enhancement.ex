defmodule Portfolio.Content.MarkdownRendering.Pipeline.Stages.TypographyEnhancement do
  @moduledoc """
  Pipeline stage that enhances text elements in the AST with typography components.

  This stage finds plain HTML text elements like headings and paragraphs and
  transforms them into typography component nodes with appropriate attributes.
  It also handles special cases like dropcaps for the first paragraph.
  """

  use Portfolio.Content.MarkdownRendering.Pipeline.Stage,
    name: "Typography Enhancement"

  alias Portfolio.Content.MarkdownRendering.AST

  @typedoc "Options for typography enhancement"
  @type enhancement_options :: %{
          optional(:first_paragraph_dropcap) => boolean(),
          optional(:heading_sizes) => %{String.t() => String.t()},
          optional(:default_font) => String.t(),
          optional(:headings_font) => String.t()
        }

  @default_options %{
    first_paragraph_dropcap: true,
    heading_sizes: %{
      "h1" => "4xl",
      "h2" => "3xl",
      "h3" => "2xl",
      "h4" => "1xl",
      "h5" => "1xs",
      "h6" => "1xs"
    },
    default_font: nil,
    headings_font: "cardinal"
  }

  @doc """
  Transforms the AST by enhancing text elements with typography components.

  This looks for HTML elements like headings and paragraphs and transforms
  them into typography component nodes with appropriate attributes.

  ## Options

  - `:first_paragraph_dropcap` - When true, the first paragraph gets dropcap styling
  - `:heading_sizes` - Map of heading tags to size attributes
  - `:default_font` - Default font for typography elements
  - `:headings_font` - Font to use for headings
  """
  @impl true
  def transform(ast, opts) do
    # Merge default options with provided options
    options =
      Map.merge(
        @default_options,
        Enum.into(opts, %{})
      )

    # Track state as we process nodes to identify the first paragraph
    state = %{first_paragraph_found: false}

    {:ok, process_nodes(ast, options, state)}
  end

  # Process a list of nodes, keeping track of state
  defp process_nodes(nodes, options, state) when is_list(nodes) do
    {result, _final_state} =
      Enum.map_reduce(nodes, state, &process_node(&1, options, &2))

    result
  end

  # Process a heading element
  defp process_node({tag, attrs, content, meta}, options, state)
       when tag in ["h1", "h2", "h3", "h4", "h5", "h6"] do
    attrs_map = attrs_to_map(attrs)

    # Get size from options map
    size = Map.get(options.heading_sizes, tag)

    # Add font for headings if configured
    attrs_map =
      if options.headings_font do
        Map.put(attrs_map, :font, options.headings_font)
      else
        attrs_map
      end

    # Add size attribute
    attrs_map = Map.put(attrs_map, :size, size)

    # Process content recursively
    processed_content = process_nodes(content, options, state)

    typography_node = AST.typography(tag, attrs_map, processed_content, meta)

    {typography_node, state}
  end

  # Process a paragraph element
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
    processed_content = process_nodes(content, options, state)

    typography_node = AST.typography("p", attrs_map, processed_content, meta)

    {typography_node, new_state}
  end

  # Process a component node
  defp process_node({:component, type, attrs, content, meta}, options, state) do
    # Process content recursively
    processed_content = process_nodes(content, options, state)

    # Return component with processed content
    {{:component, type, attrs, processed_content, meta}, state}
  end

  # Process a regular element node
  defp process_node({tag, attrs, content, meta}, options, state) do
    # Process content recursively
    processed_content = process_nodes(content, options, state)

    # Return element with processed content
    {{tag, attrs, processed_content, meta}, state}
  end

  # Pass through other node types unchanged
  defp process_node(node, _options, state) do
    {node, state}
  end

  # Convert attrs from list to map if needed
  defp attrs_to_map(attrs) when is_list(attrs) do
    Enum.into(attrs, %{})
  end

  defp attrs_to_map(attrs) when is_map(attrs) do
    attrs
  end
end
