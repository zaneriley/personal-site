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

    case Earmark.Parser.as_ast(content) do
      {:ok, ast, _} ->
        {:ok,
         %{
           frontmatter: frontmatter,
           ast: ast
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
end
