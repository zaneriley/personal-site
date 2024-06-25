defmodule Portfolio.Content.FileReader do
  @moduledoc """
  A module for reading Markdown files and extracting frontmatter and content.

  This module provides functions for reading Markdown files, extracting frontmatter and content, and converting Markdown content to HTML.

  ## Usage

  To use the FileReader module, you can call the `read_markdown_file/1` function with a file path as an argument. This function will return a tuple containing the extracted frontmatter and content.

  For example, to read a Markdown file at the path "/path/to/file.md", you can use the following code:

      {:ok, metadata, markdown} = FileReader.read_markdown_file("/path/to/file.md")

  The `metadata` variable will contain the extracted frontmatter, and the `markdown` variable will contain the extracted content.

  ## Frontmatter

  The frontmatter is a set of metadata that is extracted from the beginning of a Markdown file. It is defined by a specific format, which consists of three parts:

  1. The first line is the title, which is extracted as the first element of the frontmatter.
  2. The second line is the date, which is extracted as the second element of the frontmatter.
  3. The rest of the file is the content, which is extracted as the third element of the frontmatter.

  The frontmatter is separated from the content by a line containing three dashes (`---`). This line is used to separate the frontmatter from the content.

  ## Content

  The content is the actual content of the Markdown file, which is extracted after the frontmatter. The content is converted to HTML using the Earmark library.

  ## Example

  Consider the following Markdown file:

      ---
      title: Example Markdown File
      date: 2023-01-01
      ---
      # Heading
      Content goes here.

  """
  require Logger

  def read_markdown_file(file_path) do
    with {:ok, file_content} <- File.read(file_path),
         {:ok, metadata} <- extract_frontmatter(file_content),
         {:ok, markdown} <-
           Portfolio.ContentRenderer.extract_markdown(file_content) do
      {:ok, metadata, markdown}
    else
      {:error, :file_path_missing} ->
        Logger.error("File path is nil")
        {:error, :file_path_missing}

      {:error, reason} ->
        Logger.error(
          "Error extracting content from file #{file_path}. Reason: #{reason}"
        )

        {:error, reason}
    end
  end

  def extract_frontmatter(file_content) do
    parts = String.split(file_content, "---", parts: 3)

    case parts do
      [_, frontmatter, _] -> parse_frontmatter(frontmatter)
      _ -> {:error, :missing_frontmatter_delimiters}
    end
  end

  defp parse_frontmatter(frontmatter) do
    case :yamerl_constr.string(frontmatter) do
      [metadata] ->
        {:ok, Enum.into(metadata, %{}, &transform_metadata/1)}

      error ->
        Logger.error(
          "YAML parsing failed. Frontmatter: #{frontmatter}, Error: #{inspect(error)}"
        )

        {:error, {:yaml_parsing_failed, error}}
    end
  end

  defp transform_metadata({charlist_key, charlist_value})
       when is_list(charlist_key) and is_list(charlist_value) do
    key = String.to_atom(List.to_string(charlist_key))
    value = transform_value(charlist_value)
    {key, value}
  end

  defp transform_metadata({key, charlist_value}) when is_list(charlist_value),
    do: {key, List.to_string(charlist_value)}

  defp transform_metadata({charlist_key, value}) when is_list(charlist_key),
    do: {String.to_atom(List.to_string(charlist_key)), value}

  defp transform_metadata({key, value}), do: {key, value}

  defp transform_value([first | _] = charlist_value) when is_list(first) do
    Enum.map(charlist_value, &List.to_string/1)
  end

  defp transform_value(charlist_value) when is_list(charlist_value) do
    List.to_string(charlist_value)
  end
end
