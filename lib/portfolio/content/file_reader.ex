defmodule Portfolio.Content.FileReader do
  require Logger

  def read_markdown_file(file_path) do
    with {:ok, file_content} <- File.read(file_path),
         {:ok, metadata} <- extract_frontmatter(file_content),
         {:ok, markdown} <- Portfolio.ContentRenderer.extract_markdown(file_content) do
      {:ok, metadata, markdown}
    else
      {:error, :file_path_missing} ->
        Logger.error("File path is nil")
        {:error, :file_path_missing}
      {:error, reason} ->
        Logger.error("Error extracting content from file #{file_path}. Reason: #{reason}")
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
      [metadata] -> {:ok, Enum.into(metadata, %{}, &transform_metadata/1)}
      error ->
        Logger.error("YAML parsing failed. Frontmatter: #{frontmatter}, Error: #{inspect(error)}")
        {:error, {:yaml_parsing_failed, error}}
    end
  end

  defp transform_metadata({charlist_key, charlist_value}) when is_list(charlist_key) and is_list(charlist_value) do
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
