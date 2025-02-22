defmodule Portfolio.Content.MarkdownRendering.CustomParser do
  @moduledoc """
  Parses markdown content into a custom AST using Earmark with extended syntax.
  """

  require Logger

  @doc """
  Parses the given markdown string into an AST.
  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, String.t()}
  def parse(markdown) when is_binary(markdown) do
    {frontmatter, content} = split_frontmatter(markdown)

    # Step 1: Preprocess custom components in the content
    content = preprocess_custom_components(content)

    case Earmark.Parser.as_ast(content) do
      {:ok, ast, _} ->
        # Step 2: Process the AST to transform nodes and annotate the first paragraph
        processed_ast = process_ast(ast)

        {:ok,
         %{
           frontmatter: frontmatter,
           ast: processed_ast
         }}

      {:error, _ast, error_messages} ->
        Logger.error("Error parsing markdown: #{inspect(error_messages)}")
        {:error, "Error parsing markdown"}
    end
  end

  def split_frontmatter(markdown) do
    result = String.split(markdown, ~r/---\s*\n/, parts: 3)

    case result do
      ["", frontmatter, content] ->
        {frontmatter, content}

      _ ->
        {"", markdown}
    end
  end

  defp preprocess_custom_components(content) do
    content

    # Add more custom component preprocessing here
  end


  defp parse_attrs(attrs) do
    attrs
    |> String.split()
    |> Enum.map(fn attr ->
      [key, value] = String.split(attr, "=")
      {key, String.trim(value, "\"")}
    end)
    |> Enum.into(%{})
  end

  defp process_ast(ast) do
    # Introduce a state to track if the first paragraph is found
    {processed_ast, _state} = Enum.map_reduce(ast, %{first_paragraph_found: false}, &process_node/2)
    processed_ast
  end

  defp process_node({tag, attrs, content, meta}, state)
       when tag in ["h1", "h2", "h3", "h4", "h5", "h6", "p"] do
    default_attrs = get_default_typography_attrs(tag)
    merged_attrs = Map.merge(attrs |> Enum.into(%{}), default_attrs)
    {processed_content, state} = process_ast_with_state(content, state)

    # Annotate the first paragraph
    {dropcap, new_state} =
      if tag == "p" and not state.first_paragraph_found do
        {true, %{state | first_paragraph_found: true}}
      else
        {false, state}
      end

    meta = if dropcap, do: Map.put(meta, :dropcap, true), else: meta

    node = {:typography, tag, merged_attrs, processed_content, meta}
    {node, new_state}
  end

  defp process_node({tag, attrs, content, meta}, state) do
    {processed_content, state} = process_ast_with_state(content, state)
    node = {tag, attrs, processed_content, meta}
    {node, state}
  end

  defp process_node(content, state) when is_binary(content), do: {content, state}

  defp process_ast_with_state(ast_list, state) do
    Enum.map_reduce(ast_list, state, &process_node/2)
  end

  defp get_default_typography_attrs("h1"), do: %{font: "cardinal", size: "4xl"}
  defp get_default_typography_attrs("h2"), do: %{font: "cardinal", size: "3xl"}
  defp get_default_typography_attrs("h3"), do: %{font: "cardinal", size: "2xl"}
  defp get_default_typography_attrs("h4"), do: %{size: "1xl"}
  defp get_default_typography_attrs("h5"), do: %{size: "1xs"}
  defp get_default_typography_attrs("h6"), do: %{size: "1xs"}
  defp get_default_typography_attrs("p"), do: %{size: "md"}
  defp get_default_typography_attrs(_), do: %{}
end
