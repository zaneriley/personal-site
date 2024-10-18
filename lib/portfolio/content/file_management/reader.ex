defmodule Portfolio.Content.FileManagement.Reader do
  @moduledoc """
  Reads and parses markdown files for content management.

  Extracts content, frontmatter, and metadata from markdown files. Handles
  YAML parsing, content type determination, and locale extraction.
  """
  alias Portfolio.Content.Types
  alias Portfolio.Content.Utils.MetadataCalculator
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
         locale <- extract_locale(file_path),
         {:ok, metadata} <- MetadataCalculator.calculate(markdown, locale) do
      Logger.info("Read markdown file: #{file_path}")
      Logger.info("Extracted attributes: #{inspect(attrs)}")
      Logger.info("Extracted URL: #{inspect(attrs["url"])}")

      counting_method = get_counting_method(locale)

      word_count =
        case counting_method do
          :characters -> metadata.character_count
          :words -> metadata.word_count
          _ -> metadata.word_count || metadata.character_count
        end

      Logger.debug("READER: Metadata: #{inspect(metadata)}")
      Logger.debug("READER: Locale: #{locale}")
      Logger.debug("READER: Counting method: #{get_counting_method(locale)}")

      {:ok, content_type,
       Map.merge(attrs, %{
         "content" => markdown,
         "file_path" => file_path,
         "locale" => locale,
         "url" => attrs["url"],
         "word_count" => word_count,
         "read_time" => metadata.native_read_time_seconds
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

  defp extract_locale(file_path) do
    supported_locales = Types.get_supported_locales()
    default_locale = Application.get_env(:portfolio, :default_locale, "en")

    file_path
    |> Path.split()
    |> Enum.map(&Path.rootname/1)
    |> Enum.find(default_locale, &(&1 in supported_locales))
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

  @spec get_counting_method(String.t()) :: atom()
  defp get_counting_method(locale) do
    reading_configs =
      Application.get_env(
        :portfolio,
        Portfolio.Content.Utils.MetadataCalculator
      )[:reading_configs]

    Logger.debug("Reading configs: #{inspect(reading_configs)}")

    case Map.get(reading_configs, locale) do
      %{counting_method: method} -> method
      # Default to :words if not specified
      _ -> :words
    end
  end
end
