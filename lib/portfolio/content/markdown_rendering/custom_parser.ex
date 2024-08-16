defmodule Portfolio.Content.MarkdownRendering.CustomParser do
  @moduledoc """
  Parses markdown content into a custom AST using Earmark with extended syntax.
  """

  require Logger

  @doc """
  Parses the given markdown string into a custom AST.
  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, String.t()}
  def parse(markdown) when is_binary(markdown) do
    {frontmatter, content} = split_frontmatter(markdown)
    preprocessed_content = preprocess_custom_components(content)

    case Earmark.Parser.as_ast(preprocessed_content) do
      {:ok, ast, []} ->
        {:ok,
         %{
           frontmatter: frontmatter,
           ast: ast
         }}

      {:ok, ast, warnings} ->
        Logger.warning("Warnings while parsing markdown: #{inspect(warnings)}")

        {:ok,
         %{
           frontmatter: frontmatter,
           ast: ast
         }}

      {:error, _ast, error_messages} ->
        {:error, "Error parsing markdown: #{inspect(error_messages)}"}
    end
  end

  defp split_frontmatter(markdown) do
    case String.split(markdown, ~r/---\s*\n/, parts: 3) do
      ["", frontmatter, content] -> {frontmatter, content}
      _ -> {"", markdown}
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
end
