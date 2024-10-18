defmodule Portfolio.Content.Utils.MetadataCalculator do
  @moduledoc """
  Provides utilities for calculating metadata of markdown content, including word count, image count,
  code word count, and estimated reading times based on locale-specific reading speeds.

  ## Functions

    - `calculate/2`: Calculates metadata for given content and locale.
    - `word_count/2`: Counts words or characters in the content based on locale.
    - `image_count/1`: Counts images in the markdown content.
    - `read_time/3`: Calculates estimated read time based on content metrics and locale.

  ## Example

      iex> content = "# Hello World\\nThis is a sample markdown with an image ![Alt text](image.png)."
      iex> Portfolio.Content.Utils.MetadataCalculator.calculate(content, "en")
      {:ok, %{
        word_count: 6,
        image_count: 1,
        code_word_count: 0,
        non_native_read_time_seconds: 80,
        native_read_time_seconds: 70
      }}
  """

  alias Portfolio.Content.Types
  require Logger

  # seconds per image
  @image_read_time_seconds 10

  @reading_configs Application.compile_env!(:portfolio, __MODULE__)[
                     :reading_configs
                   ]

  @doc """
  Calculates word/character count, code word count, image count, and estimated read times.

  ## Parameters

    - `content`: The markdown content to analyze.
    - `locale`: The locale identifier used for reading speed configurations.

  ## Returns

    - `{:ok, result_map}` on success.
    - `{:error, message}` if the locale is unsupported.

  The `result_map` includes:
    - `word_count` or `character_count`
    - `code_word_count`
    - `image_count`
    - `native_read_time_seconds`
    - `non_native_read_time_seconds`
  """
  @spec calculate(String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def calculate(content, locale) do
    case get_reading_config(locale) do
      {:ok, reading_config} ->
        # Parse the markdown content into an AST using EarmarkParser
        {:ok, ast, _} = Earmark.Parser.as_ast(content)

        text_count_map = calculate_text_count(ast, reading_config)
        code_word_count = calculate_code_count(ast)
        image_count = image_count_from_ast(ast)

        reading_speeds = %{
          native: %{
            text: reading_config.native_reading_speed,
            code: reading_config.code_reading_speed
          },
          non_native: %{
            text: reading_config.non_native_reading_speed,
            code: reading_config.code_reading_speed
          }
        }

        non_native_time_seconds =
          read_time_seconds(
            text_count_map,
            code_word_count,
            image_count,
            reading_speeds.non_native
          )

        native_time_seconds =
          read_time_seconds(
            text_count_map,
            code_word_count,
            image_count,
            reading_speeds.native
          )

        result =
          Map.merge(
            %{
              image_count: image_count,
              code_word_count: code_word_count,
              non_native_read_time_seconds: non_native_time_seconds,
              native_read_time_seconds: native_time_seconds
            },
            text_count_map
          )

        {:ok, result}

      {:error, message} ->
        {:error, message}
    end
  end

  # Configuration Functions

  @doc false
  @spec get_reading_config(String.t()) :: {:ok, map()} | {:error, String.t()}
  defp get_reading_config(locale) do
    case @reading_configs[locale] do
      nil -> {:error, "Unsupported locale: #{locale}"}
      config -> {:ok, config}
    end
  end

  # Calculation Functions

  @doc false
  @spec calculate_text_count(list(), map()) :: map()
  defp calculate_text_count(ast, %{counting_method: :words} = _config) do
    text =
      extract_text_from_ast(ast, exclude_code: true)
      |> Enum.join(" ")

    word_count =
      text
      |> String.split(~r/\s+/)
      |> Enum.count(fn token ->
        token != "" and word_token?(token)
      end)

    %{word_count: word_count}
  end

  @doc false
  @spec calculate_text_count(list(), map()) :: map()
  defp calculate_text_count(ast, %{counting_method: :characters} = _config) do
    text =
      extract_text_from_ast(ast, exclude_code: true)
      |> Enum.join("")
      |> String.replace(~r/\s+/, "")
      # Exclude certain punctuation
      |> String.replace(~r/[、。！？：「」（）【】]/u, "")

    char_count = String.length(text)
    %{character_count: char_count}
  end

  @doc false
  @spec calculate_code_count(list()) :: integer()
  defp calculate_code_count(ast) do
    code_text =
      extract_code_from_ast(ast)
      |> Enum.join(" ")

    code_word_count =
      code_text
      |> String.split(~r/\s+/)
      |> Enum.count(&(&1 != ""))

    code_word_count
  end

  @doc false
  @spec read_time_seconds(map(), integer(), integer(), map()) :: integer()
  defp read_time_seconds(text_count_map, code_word_count, image_count, %{
         text: text_speed,
         code: code_speed
       }) do
    image_time = image_count * @image_read_time_seconds
    text_count = Map.values(text_count_map) |> hd()

    text_read_time = Float.ceil(text_count / text_speed * 60)

    code_read_time =
      if code_word_count > 0 do
        Float.ceil(code_word_count / code_speed * 60)
      else
        0
      end

    trunc(text_read_time + code_read_time + image_time)
  end

  # AST Parsing and Extraction Functions

  @doc false
  @spec extract_text_from_ast(any(), keyword()) :: [String.t()]
  defp extract_text_from_ast(ast, opts \\ [])

  defp extract_text_from_ast(ast, opts) do
    exclude_code = Keyword.get(opts, :exclude_code, false)
    do_extract_text_from_ast(ast, exclude_code)
  end

  @doc false
  @spec do_extract_text_from_ast(any(), boolean()) :: [String.t()]
  defp do_extract_text_from_ast([head | tail], exclude_code) do
    do_extract_text_from_ast(head, exclude_code) ++
      do_extract_text_from_ast(tail, exclude_code)
  end

  defp do_extract_text_from_ast({"code", _, _, _}, true), do: []
  defp do_extract_text_from_ast({"pre", _, _, _}, true), do: []

  defp do_extract_text_from_ast({_tag, _attrs, children, _meta}, exclude_code) do
    do_extract_text_from_ast(children, exclude_code)
  end

  defp do_extract_text_from_ast(text, _exclude_code) when is_binary(text),
    do: [text]

  defp do_extract_text_from_ast(_other, _exclude_code), do: []

  @doc false
  @spec extract_code_from_ast(any()) :: [String.t()]
  defp extract_code_from_ast(ast)

  defp extract_code_from_ast([head | tail]) do
    extract_code_from_ast(head) ++ extract_code_from_ast(tail)
  end

  defp extract_code_from_ast({"code", _attrs, content, _meta}) do
    extract_text(content)
  end

  defp extract_code_from_ast({"pre", _attrs, content, _meta}) do
    extract_text(content)
  end

  defp extract_code_from_ast({_tag, _attrs, _children, _meta}), do: []
  defp extract_code_from_ast(_), do: []

  @doc false
  @spec extract_text(any()) :: [String.t()]
  defp extract_text(content) when is_list(content) do
    Enum.flat_map(content, &extract_text/1)
  end

  defp extract_text({_, _, children, _}) do
    extract_text(children)
  end

  defp extract_text(text) when is_binary(text), do: [text]
  defp extract_text(_), do: []

  @doc false
  @spec image_count_from_ast(any()) :: integer()
  defp image_count_from_ast(ast) do
    Enum.reduce(ast, 0, fn
      {"img", _, _, _}, acc ->
        acc + 1

      {"figure", _, _, _}, acc ->
        acc + 1

      {_tag, _attrs, children, _meta}, acc ->
        acc + image_count_from_ast(children)

      _, acc ->
        acc
    end)
  end

  # Utility Functions

  @doc """
  Counts words or characters in the content based on locale.

  ## Parameters

    - `content`: The markdown content to analyze.
    - `locale`: The locale to determine counting method.

  ## Returns

    - `{:ok, integer()}`: The word or character count.
    - `{:error, message}` if the locale is unsupported.
  """
  @spec word_count(String.t(), String.t()) ::
          {:ok, integer()} | {:error, String.t()}
  def word_count(content, locale) do
    case get_reading_config(locale) do
      {:ok, config} ->
        {:ok, ast, _} = Earmark.Parser.as_ast(content)
        count_map = calculate_text_count(ast, config)
        {:ok, Map.values(count_map) |> hd()}

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Counts images in the markdown content.

  ## Parameters

    - `content`: The markdown content to analyze.

  ## Returns

    - `integer()`: The number of images found.
  """
  @spec image_count(String.t()) :: integer()
  def image_count(content) do
    {:ok, ast, _} = Earmark.Parser.as_ast(content)
    image_count_from_ast(ast)
  end

  @doc """
  Calculates read time based on count, image count, and locale.

  ## Parameters

    - `count`: The word or character count, depending on locale.
    - `image_count`: The number of images in the content.
    - `locale`: The locale identifier.

  ## Returns

    - `{:ok, %{min: integer(), max: integer()}}`: A map with min and max read times in seconds.
    - `{:error, message}` if the locale is unsupported.
  """
  @spec read_time(integer(), integer(), String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def read_time(count, image_count, locale) do
    case get_reading_config(locale) do
      {:ok, config} ->
        image_time = image_count * @image_read_time_seconds

        non_native_time = count / config.non_native_reading_speed * 60
        native_time = count / config.native_reading_speed * 60

        {:ok,
         %{
           min: trunc(Float.ceil(native_time + image_time)),
           max: trunc(Float.ceil(non_native_time + image_time))
         }}

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Determines if a token is considered a word token.

  ## Parameters

    - `token`: The string token to evaluate.

  ## Returns

    - `true` if the token contains letters or numbers.
    - `false` otherwise.
  """
  @spec word_token?(String.t()) :: boolean()
  def word_token?(token) do
    # Matches tokens containing at least one letter or number
    Regex.match?(~r/\p{L}|\p{N}/u, token)
  end
end
