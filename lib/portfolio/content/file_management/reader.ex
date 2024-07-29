defmodule Portfolio.Content.FileManagement.Reader do
  @moduledoc """
  Reads and parses markdown files for content management.

  Extracts content, frontmatter, and metadata from markdown files. Handles
  YAML parsing, content type determination, and locale extraction.
  """
  alias Portfolio.Content.Types
  require Logger

  @doc """
  Reads a markdown file and extracts its content, frontmatter, and metadata.

  ## Parameters
    - file_path: String representing the path to the markdown file

  ## Returns
    - {:ok, content_type, attrs} if successful
    - {:error, reason} if an error occurs
  """
  @spec read_markdown_file(String.t()) ::
          {:ok, String.t(), map()} | {:error, term()}
  def read_markdown_file(file_path) do
    with {:ok, content} <- File.read(file_path),
         {:ok, frontmatter, markdown} <- split_frontmatter_and_content(content),
         {:ok, attrs} <- parse_frontmatter(frontmatter),
         {:ok, content_type} <- determine_content_type(file_path),
         locale <- extract_locale(file_path) do
      Logger.info(
        "Successfully read markdown file: #{file_path}, content_type: #{content_type}, locale: #{locale}"
      )

      {:ok, content_type,
       Map.merge(attrs, %{
         "content" => markdown,
         "file_path" => file_path,
         "locale" => locale,
         "url" => attrs["url"]
       })}
    else
      {:error, reason} = error ->
        Logger.error(
          "Error reading markdown file: #{file_path}, error: #{inspect(reason)}"
        )

        error
    end
  end

  @spec split_frontmatter_and_content(String.t()) ::
          {:ok, String.t(), String.t()} | {:error, atom()}
  defp split_frontmatter_and_content(content) do
    case String.split(content, ~r/---\s*\n/, parts: 3) do
      ["", frontmatter, markdown] -> {:ok, frontmatter, markdown}
      # Corrected atom syntax
      _ -> {:error, :invalid_markdown_format}
    end
  end

  @spec parse_frontmatter(String.t()) :: {:ok, map()} | {:error, tuple()}
  defp parse_frontmatter(frontmatter) do
    if Application.get_env(:portfolio, :environment) in [:dev, :test] do
      case :yamerl_constr.string(frontmatter) do
        [metadata] ->
          {:ok, Enum.into(metadata, %{}, &transform_metadata/1)}

        error ->
          Logger.error(
            "YAML parsing failed. Frontmatter: #{frontmatter}, Error: #{inspect(error)}"
          )

          {:error, {:yaml_parsing_failed, error}}
      end
    else
      {:ok, %{}}
    end
  end

  @spec determine_content_type(String.t()) ::
          {:ok, String.t()} | {:error, :unknown_content_type}
  defp determine_content_type(file_path) do
    case Types.get_type(file_path) do
      {:ok, type} ->
        {:ok, type}

      {:error, :unknown_content_type} = error ->
        Logger.error("Unable to determine content type for: #{file_path}")
        error
    end
  end

  @spec extract_locale(String.t()) :: String.t()
  defp extract_locale(file_path) do
    file_path
    |> String.split("/")
    |> Enum.at(-2)
  end

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
end
