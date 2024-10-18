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
        # Step 2: Process the AST to transform nodes
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
    |> preprocess_custom_images()

    # Add more custom component preprocessing here
  end

  defp preprocess_custom_images(content) do
    Regex.replace(~r/!\[(.*?)\]\((.*?)\){(.*?)}/, content, fn _,
                                                              alt,
                                                              src,
                                                              attrs ->
      "{:custom_image, #{inspect(alt)}, #{inspect(src)}, #{inspect(parse_attrs(attrs))}}"
    end)
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
    Enum.map(ast, &process_node/1)
  end

  defp process_node({tag, attrs, content, meta})
       when tag in ["h1", "h2", "h3", "h4", "h5", "h6", "p"] do
    default_attrs = get_default_typography_attrs(tag)
    merged_attrs = Map.merge(attrs |> Enum.into(%{}), default_attrs)
    {:typography, tag, merged_attrs, process_ast(content), meta}
  end

  defp process_node({tag, attrs, content, meta}) do
    {tag, attrs, process_ast(content), meta}
  end

  defp process_node(content) when is_binary(content), do: content

  defp get_default_typography_attrs("h1"), do: %{font: "cardinal", size: "4xl"}
  defp get_default_typography_attrs("h2"), do: %{font: "cardinal", size: "3xl"}
  defp get_default_typography_attrs("h3"), do: %{font: "cardinal", size: "2xl"}
  defp get_default_typography_attrs("h4"), do: %{size: "1xl"}
  defp get_default_typography_attrs("h5"), do: %{size: "1xs"}
  defp get_default_typography_attrs("h6"), do: %{size: "1xs"}
  defp get_default_typography_attrs("p"), do: %{size: "md"}
  defp get_default_typography_attrs(_), do: %{}
end
