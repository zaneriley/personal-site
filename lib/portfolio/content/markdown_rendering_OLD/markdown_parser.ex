defmodule Portfolio.Content.MarkdownRendering.MarkdownParser do
  @moduledoc """
  Parses markdown content into a structured AST using Earmark with extended syntax.

  This module handles the initial parsing of markdown into an AST structure,
  including frontmatter extraction and custom component syntax processing.
  """

  require Logger

  @doc """
  Parses the given markdown string into an AST.

  This function extracts frontmatter, processes custom component syntax,
  and parses the markdown content into an AST structure. The actual
  transformation of the AST is handled by the pipeline.
  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, String.t()}
  def parse(markdown) when is_binary(markdown) do
    {frontmatter_map, content} = split_frontmatter(markdown)

    # Process custom components in the content
    {content, custom_components} = preprocess_custom_components(content)

    case Earmark.Parser.as_ast(content) do
      {:ok, ast, _} ->
        # Insert custom components back into the AST
        ast_with_components = insert_custom_components(ast, custom_components)

        # Return the raw AST with frontmatter
        {:ok,
         %{
           frontmatter: frontmatter_map,
           ast: ast_with_components
         }}

      {:error, _ast, error_messages} ->
        Logger.error("Error parsing markdown: #{inspect(error_messages)}")
        {:error, "Error parsing markdown"}
    end
  end

  @doc """
  Splits the markdown content into frontmatter and content sections,
  and parses the frontmatter into a map.
  """
  def split_frontmatter(markdown) do
    result = String.split(markdown, ~r/---\s*\n/, parts: 3)

    case result do
      ["", frontmatter_str, content] ->
        # Parse the frontmatter string to a map
        frontmatter_map = parse_yaml_frontmatter(frontmatter_str)
        {frontmatter_map, content}

      _ ->
        # Return empty map instead of empty string
        {%{}, markdown}
    end
  end

  # Updated to extract custom components
  defp preprocess_custom_components(content) do
    # Regex to match custom component syntax
    # Matches: ::component{attr1=value attr2="value2"}...::end-component
    component_regex = ~r/::([a-zA-Z0-9_-]+)\{([^}]*)\}(.*?)::end-\1/s

    # Find all matches
    matches = Regex.scan(component_regex, content, capture: :all)

    # Replace matches with placeholders and collect component info
    {final_content, components} =
      Enum.reduce(matches, {content, []}, fn [
                                               full_match,
                                               component_name,
                                               attributes_str,
                                               inner_content
                                             ],
                                             {current_content, components_acc} ->
        placeholder = "COMPONENT_PLACEHOLDER_#{length(components_acc)}"

        # Parse attributes
        attributes = parse_component_attrs(attributes_str)

        # Replace the component with a placeholder in the content
        new_content =
          String.replace(current_content, full_match, placeholder,
            global: false
          )

        # Add component to the accumulator
        new_components =
          components_acc ++
            [
              %{
                type: String.to_atom(component_name),
                attrs: attributes,
                content: inner_content,
                placeholder: placeholder
              }
            ]

        {new_content, new_components}
      end)

    {final_content, components}
  end

  # Parse component attributes from string
  defp parse_component_attrs(attrs_str) do
    # Regex to match attributes: key=value or key="value with spaces"
    attr_regex = ~r/([a-zA-Z0-9_-]+)=(?:"([^"]*)"|([^"\s]*))/

    matches = Regex.scan(attr_regex, attrs_str)

    Enum.reduce(matches, %{}, fn
      # Handle quoted values
      [_, key, quoted_value, ""], acc ->
        if quoted_value != "" do
          Map.put(acc, String.to_atom(key), quoted_value)
        else
          acc
        end

      # Handle simple values
      [_, key, "", simple_value], acc ->
        # Convert types appropriately
        parsed_value = parse_attr_value(simple_value)
        Map.put(acc, String.to_atom(key), parsed_value)

      _, acc ->
        # Skip malformed attributes
        acc
    end)
  end

  # Parse attribute values to appropriate Elixir types
  defp parse_attr_value("true"), do: true
  defp parse_attr_value("false"), do: false

  defp parse_attr_value(value) do
    # Try parsing as integer
    case Integer.parse(value) do
      {int_value, ""} ->
        int_value

      _ ->
        # Try parsing as float
        case Float.parse(value) do
          {float_value, ""} ->
            float_value

          _ ->
            # Keep as string if not a number
            value
        end
    end
  end

  # Insert custom components back into the AST using their placeholders
  defp insert_custom_components(ast, []), do: ast

  defp insert_custom_components(ast, components) do
    Enum.reduce(components, ast, fn component, current_ast ->
      placeholder = component.placeholder

      Enum.map(current_ast, fn
        _node = {_tag, _attrs, content, _meta}
        when is_binary(content) and content == placeholder ->
          # Replace text node with component node
          process_custom_component(component)

        {tag, attrs, content, meta} ->
          # Process children recursively
          {tag, attrs, insert_custom_components(content, [component]), meta}

        other ->
          other
      end)
    end)
  end

  # Process a custom component into an AST node
  defp process_custom_component(component) do
    # Parse the inner content to get AST for component content
    case Earmark.Parser.as_ast(component.content) do
      {:ok, inner_ast, _} ->
        # Create component node
        {:component, component.type, component.attrs, inner_ast, %{}}

      _ ->
        # Fallback if parsing fails
        {:component, component.type, component.attrs, [], %{}}
    end
  end

  # Parse YAML frontmatter using yamerl
  defp parse_yaml_frontmatter(frontmatter) do
    try do
      case :yamerl_constr.string(frontmatter) do
        [metadata] ->
          Enum.into(metadata, %{}, &transform_metadata/1)

        _ ->
          %{}
      end
    rescue
      _ -> %{}
    end
  end

  # Transform yamerl output to Elixir maps
  @spec transform_metadata({charlist() | atom(), charlist() | term()}) ::
          {String.t(), String.t() | [String.t()] | term()}
  defp transform_metadata({charlist_key, charlist_value})
       when is_list(charlist_key) and is_list(charlist_value) do
    key = List.to_string(charlist_key)
    value = transform_value(charlist_value)
    {key, value}
  end

  defp transform_metadata({key, charlist_value}) when is_list(charlist_value),
    do: {to_string(key), List.to_string(charlist_value)}

  defp transform_metadata({charlist_key, value}) when is_list(charlist_key),
    do: {List.to_string(charlist_key), value}

  defp transform_metadata({key, value}), do: {to_string(key), value}

  @spec transform_value(charlist() | [charlist()]) :: String.t() | [String.t()]
  defp transform_value([first | _] = charlist_value) when is_list(first) do
    Enum.map(charlist_value, &List.to_string/1)
  end

  defp transform_value(charlist_value) when is_list(charlist_value) do
    List.to_string(charlist_value)
  end

  defp transform_value(value), do: value
end
