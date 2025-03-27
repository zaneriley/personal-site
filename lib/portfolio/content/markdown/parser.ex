defmodule Portfolio.Content.Markdown.Parser do
  @moduledoc """
  Parses raw Markdown text into an initial Abstract Syntax Tree (AST).

  This module acts as the bridge between the raw text content (potentially including
  YAML frontmatter) and a structured AST suitable for further processing by the
  `Portfolio.Content.Markdown.Pipeline`.

  It performs two key functions:
  1.  **Standard Markdown Parsing:** Leverages the `Earmark` library to parse standard
      Markdown syntax (headings, lists, links, etc.) into an AST.
  2.  **(Planned) Custom Component Syntax Handling:** Includes logic (currently marked with TODOs
      in `preprocess_custom_components` and `insert_custom_components`) to recognize, extract,
      and represent custom component blocks (e.g., `::my-component{...} ... ::end::`)
      within the final AST structure. This typically involves pre-processing the raw string
      before Earmark runs and post-processing the Earmark AST to insert the custom nodes.

  The output is a map containing the parsed frontmatter and the initial AST, which
  represents the document's structure including both standard elements and placeholders
  or nodes for custom components.
  """

  require Logger

  @doc """
  Parses markdown content into an AST structure.

  This function:
  1. Extracts and parses frontmatter metadata
  2. Processes any custom component syntax
  3. Parses the markdown into an AST using Earmark
  4. Returns a structured map with both the frontmatter and AST

  ## Parameters
    - markdown: The raw markdown string to parse

  ## Returns
    - {:ok, %{frontmatter: map(), ast: list()}} on success
    - {:error, reason} on failure
  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, String.t()}
  def parse(markdown) when is_binary(markdown) do
    {frontmatter_map, content} = split_frontmatter(markdown)

    # Process custom components (if any)
    {processed_content, custom_components} =
      preprocess_custom_components(content)

    case Earmark.Parser.as_ast(processed_content) do
      {:ok, ast, _} ->
        # Insert custom components back into the AST if any were extracted
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
  Splits the markdown content into frontmatter and content sections.

  Frontmatter is delimited by triple dashes (---) and uses YAML syntax.

  ## Parameters
    - markdown: The raw markdown string

  ## Returns
    - {frontmatter_map, content} where frontmatter_map is a map of parsed YAML
      and content is the remaining markdown without the frontmatter section
  """
  @spec split_frontmatter(String.t()) :: {map(), String.t()}
  def split_frontmatter(markdown) do
    result = String.split(markdown, ~r/---\s*\n/, parts: 3)

    case result do
      ["", frontmatter_str, content] ->
        # Parse the frontmatter string to a map
        frontmatter_map = parse_yaml_frontmatter(frontmatter_str)
        {frontmatter_map, content}

      _ ->
        # No frontmatter found, return empty map and original content
        {%{}, markdown}
    end
  end

  # Private helper functions

  # Parse YAML frontmatter into an Elixir map
  defp parse_yaml_frontmatter(frontmatter) do
    try do
      case :yamerl_constr.string(frontmatter) do
        [metadata] ->
          Enum.into(metadata, %{}, &transform_yaml_entry/1)

        _ ->
          %{}
      end
    rescue
      _ -> %{}
    end
  end

  # Transform YAML entries from yamerl format to Elixir values
  defp transform_yaml_entry({key, value}) when is_list(key) do
    # Convert charlist keys to strings
    {to_string(key), transform_yaml_value(value)}
  end

  defp transform_yaml_entry({key, value}) do
    # Handle atom keys
    {to_string(key), transform_yaml_value(value)}
  end

  # Transform various YAML value types
  defp transform_yaml_value(value) when is_list(value) do
    # Check if it's a charlist (string) or a list
    if Enum.all?(value, &is_integer/1) and value != [] do
      # It's a charlist (string)
      List.to_string(value)
    else
      # It's a list, recursively transform each item
      Enum.map(value, &transform_yaml_value/1)
    end
  end

  defp transform_yaml_value(value), do: value

  # Custom component preprocessing to extract component blocks before Earmark parsing
  defp preprocess_custom_components(content) do
    # TODO: Implement custom component extraction
    # For now, just return the content unchanged with no components
    {content, []}
  end

  # Insert custom components back into the AST
  defp insert_custom_components(ast, []), do: ast

  defp insert_custom_components(ast, _components) do
    # TODO: Implement custom component insertion
    # For now, just return the AST unchanged
    ast
  end
end
