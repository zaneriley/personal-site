defmodule Portfolio.Content.MarkdownRendering.ComponentBuilder do
  @moduledoc """
  Transforms parsed Markdown AST into a Component AST that can be rendered
  with Phoenix components.

  This module takes the output from the Pipeline processing (a processed AST) and
  converts it to Phoenix components that can be rendered in HTML.
  """

  require Logger
  alias PortfolioWeb.Components.Typography
  alias PortfolioWeb.Components.ColumnLayout
  alias Portfolio.Content.MarkdownRendering.Components.Registry
  alias Portfolio.Content.Types

  @doc """
  Renders the given content AST to HTML.

  ## Parameters
    - content: A map containing the AST to be rendered
    - opts: Optional keyword list of rendering options
      - `:content_type` - The type of content being rendered

  ## Returns
    - {:ok, html_string} if rendering is successful
    - {:error, reason} if rendering fails
  """
  @spec render(map() | any(), keyword()) ::
          {:ok, String.t()} | {:error, String.t()}
  def render(content \\ %{}, opts \\ [])

  # Implementation for AST content
  def render(%{ast: ast}, opts) when is_list(ast) do
    _content_type = Keyword.get(opts, :content_type, :note)

    try do
      # Transform the AST to Component AST
      component_ast = Enum.map(ast, &transform_node/1)

      # Return the component AST directly instead of converting to HTML
      {:ok, component_ast}
    rescue
      e ->
        Logger.error("Failed to compile AST: #{inspect(e)}")
        {:error, "Failed to compile content: #{inspect(e)}"}
    end
  end

  # Implementation for invalid content
  def render(content, _opts) do
    Logger.error(
      "Invalid content provided to ComponentBuilder: #{inspect(content)}"
    )

    {:error, "Invalid content"}
  end

  # Transform component nodes to their Phoenix component equivalents
  defp transform_node({:component, component_type, attrs, content, _meta}) do
    # Custom handling for specific component types
    case component_type do
      :column_layout ->
        transform_column_layout(attrs, content)

      _ ->
        # Default handling for other component types
        # Transform any nested content
        transformed_content = Enum.map(content, &transform_node/1)

        # Look up the component in the registry
        case Registry.lookup_component(component_type) do
          {:ok, {module, function}} ->
            # Component found in registry, use it
            {:component, module, function, attrs, transformed_content}

          {:error, :component_not_found} ->
            # Component not found, log warning and use fallback
            Logger.warning("Unknown component type: #{inspect(component_type)}")
            {:component, :unknown, attrs, transformed_content}
        end
    end
  end

  # Transform column layout node to ColumnLayout component
  defp transform_column_layout(attrs, content) do
    # Transform nested content
    transformed_content = Enum.map(content, &transform_node/1)

    # Get column specifications from attrs
    columns = Map.get(attrs, :columns, [])

    # Create column slots
    column_slots =
      if length(columns) > 0 do
        # For simplicity in the prototype, we'll put all content in the first column
        [
          %{
            __slot__: :column,
            inner_block: fn -> transformed_content end,
            index: 0
          }
        ]
      else
        []
      end

    # Look up the component in the registry (but we know it's ColumnLayout)
    case Registry.lookup_component(:column_layout) do
      {:ok, {module, function}} ->
        # Return component with slots
        {:component, module, function, attrs, column_slots}

      {:error, :component_not_found} ->
        # Fallback if not registered
        Logger.warning("ColumnLayout component not found in registry")
        {:component, ColumnLayout, :column_layout, attrs, column_slots}
    end
  end

  # Transform typography nodes to Typography component
  defp transform_node({:typography, tag, attrs, content, meta}) do
    {:component, Typography, :typography,
     Map.merge(attrs, %{
       tag: tag,
       dropcap: Map.get(meta, :dropcap, false)
     }), transform_content(content)}
  end

  # Transform heading nodes to typography components
  defp transform_node({"h" <> level = tag, _attrs, content, _meta})
       when level in ["1", "2", "3", "4", "5", "6"] do
    {:component, Typography, :typography,
     %{
       tag: tag,
       size: get_size_for_heading(String.to_integer(level)),
       dropcap: false
     }, transform_content(content)}
  end

  # Transform paragraph nodes to typography components
  defp transform_node({"p", _attrs, content, meta}) do
    {:component, Typography, :typography,
     %{
       tag: "p",
       size: "md",
       dropcap: meta[:first_paragraph] || false
     }, transform_content(content)}
  end

  # Transform image nodes to registered component, if available
  defp transform_node({"img", attrs, [], _meta}) do
    # For image nodes, create attributes map from the attribute list
    attrs_map = attrs_to_map(attrs)

    # Look up the :figure component in the registry
    case Registry.lookup_component(:figure) do
      {:ok, {module, function}} ->
        # If the figure component is registered, use it
        {:component, module, function, attrs_map, []}

      {:error, :component_not_found} ->
        # If not registered, just pass through the image
        {"img", attrs, [], %{}}
    end
  end

  # Transform text nodes
  defp transform_node(content) when is_binary(content), do: content

  # Default transformation for other nodes
  defp transform_node({tag, attrs, content, meta}) do
    {tag, attrs, transform_content(content), meta}
  end

  # Transform lists of nodes
  defp transform_content(content) when is_list(content) do
    Enum.map(content, &transform_node/1)
  end

  defp transform_content(content), do: content

  defp get_size_for_heading(level) do
    case level do
      1 -> "4xl"
      2 -> "3xl"
      3 -> "2xl"
      4 -> "1xl"
      5 -> "1xs"
      _ -> "1xs"
    end
  end

  # Convert a list of attribute tuples to a map
  defp attrs_to_map(attrs) do
    Enum.reduce(attrs, %{}, fn
      {key, value}, acc when is_binary(key) ->
        # Convert key to atom if it's a string
        Map.put(acc, String.to_atom(key), value)

      {key, value}, acc ->
        # Key is already an atom
        Map.put(acc, key, value)
    end)
  end

  # Render component AST to HTML using Phoenix.Component
  @spec render_to_html(list(), Types.content_type()) :: String.t()
  defp render_to_html(component_ast, content_type) do
    try do
      # Convert the component AST to Phoenix LiveView HTML Safe format
      # In a real implementation, this would use Phoenix's HTML rendering
      # For now, we'll use a simple approximation
      html_string = ast_to_html_string(component_ast)

      # Add wrapper based on content type
      case content_type do
        :note -> "<div class=\"note-content\">#{html_string}</div>"
        :post -> "<article class=\"post-content\">#{html_string}</article>"
        :project -> "<div class=\"project-content\">#{html_string}</div>"
        _ -> html_string
      end
    rescue
      e ->
        Logger.error("Error rendering component AST to HTML: #{inspect(e)}")
        "<div class=\"error\">Error rendering content</div>"
    end
  end

  # Convert component AST to HTML string
  defp ast_to_html_string(ast) when is_list(ast) do
    Enum.map_join(ast, "\n", &ast_to_html_string/1)
  end

  # Convert component to HTML string
  defp ast_to_html_string({:component, module, function, attrs, children}) do
    # Get component tag and class
    {tag, class} = get_component_tag_class(module, function, attrs)

    # Get component attributes as HTML attribute string
    attr_string = attrs_to_string(attrs)

    # Get children as HTML string
    children_string = ast_to_html_string(children)

    # Build HTML tag
    if children_string == "" do
      "<#{tag} class=\"#{class}\" #{attr_string} />"
    else
      "<#{tag} class=\"#{class}\" #{attr_string}>#{children_string}</#{tag}>"
    end
  end

  # Convert regular HTML node to HTML string
  defp ast_to_html_string({tag, attrs, content, _meta}) when is_binary(tag) do
    # Convert attributes to string
    attr_string =
      attrs
      |> Enum.map_join(" ", fn {k, v} -> "#{k}=\"#{v}\"" end)

    # Convert content to string
    content_string = ast_to_html_string(content)

    # Build HTML tag
    if content_string == "" do
      "<#{tag} #{attr_string} />"
    else
      "<#{tag} #{attr_string}>#{content_string}</#{tag}>"
    end
  end

  # Handle text nodes
  defp ast_to_html_string(text) when is_binary(text), do: text

  # Handle other node types
  defp ast_to_html_string(_), do: ""

  # Get tag and class for component
  defp get_component_tag_class(module, function, attrs) do
    case {module, function} do
      {Typography, :typography} ->
        {Map.get(attrs, :tag, "p"), "typography-#{Map.get(attrs, :size, "md")}"}

      {ColumnLayout, :column_layout} ->
        {"div", "column-layout"}

      _ ->
        {"div", "component-#{function}"}
    end
  end

  # Convert attributes map to HTML attribute string
  defp attrs_to_string(attrs) do
    attrs
    |> Enum.filter(fn {k, _} ->
      k not in [:tag, :size, :dropcap, :columns]
    end)
    |> Enum.map_join(" ", fn {k, v} -> "#{k}=\"#{v}\"" end)
  end

  @doc """
  Converts component AST to HTML string.

  ## Parameters
    - component_ast: The component AST to convert
    - content_type: The type of content being rendered

  ## Returns
    - html_string: The HTML string representation of the component AST
  """
  @spec to_html(list(), Types.content_type()) :: String.t()
  def to_html(component_ast, content_type \\ :note)
      when is_list(component_ast) do
    try do
      # Convert the component AST to HTML string
      html_string = ast_to_html_string(component_ast)

      # Add wrapper based on content type
      case content_type do
        :note -> "<div class=\"note-content\">#{html_string}</div>"
        :post -> "<article class=\"post-content\">#{html_string}</article>"
        :project -> "<div class=\"project-content\">#{html_string}</div>"
        _ -> html_string
      end
    rescue
      e ->
        Logger.error("Error rendering component AST to HTML: #{inspect(e)}")
        "<div class=\"error\">Error rendering content</div>"
    end
  end
end
