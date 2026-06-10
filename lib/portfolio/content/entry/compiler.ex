defmodule Portfolio.Content.Entry.Compiler do
  @moduledoc """
  Responsible for compiling content entries into renderable formats.

  This module handles the transformation of raw content (like markdown)
  into compiled formats (like HTML) and manages the AST (Abstract Syntax Tree)
  representation of content that can be used for rendering.

  The compiler works with both the raw content string and the AST
  representation, providing functions to:
  - Parse markdown into AST
  - Process and transform AST nodes
  - Compile content with various options like language and translations
  """

  alias Portfolio.Content.Markdown.Parser
  alias Portfolio.Content.Markdown.Pipeline
  alias Portfolio.Content.Markdown.Renderer
  alias Portfolio.Content.Markdown.Transforms
  alias Portfolio.Content.Entry.AstSerialization
  alias Portfolio.Content.Schemas.Translation
  alias Portfolio.Content.TranslationRepository
  alias Portfolio.Content.Utils.LanguageUtils

  require Logger

  @type ast :: EarmarkParser.ast()

  @doc """
  Parses raw markdown content into an AST representation.

  ## Parameters
    - content: The raw markdown content to parse

  ## Returns
    - A tuple with the result and AST: `{:ok, ast}` or `{:error, reason}`
  """
  @spec parse_to_ast(String.t() | nil) :: {:ok, ast()} | {:error, any()}
  def parse_to_ast(nil) do
    {:error, "Cannot parse nil content"}
  end

  def parse_to_ast(content) when is_binary(content) do
    try do
      case Parser.parse(content) do
        {:ok, %{ast: ast}} ->
          {:ok, ast}

        {:error, reason} ->
          Logger.error("Parser returned an error: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      e ->
        Logger.error("Error parsing content to AST: #{inspect(e)}")
        {:error, "Failed to parse content"}
    end
  end

  @doc """
  Processes an AST with various transformations to prepare it for rendering.

  ## Parameters
    - ast: The AST to process
    - opts: Options for processing (e.g., locale, transforms)

  ## Returns
    - The processed AST
  """
  # Compile-time pipeline stages: transforms whose work is baked into the
  # stored AST once at publish time. The same stages run on the read path as
  # cheap no-op walks (their target nodes are already rewritten).
  @compile_stages [Transforms.CodeBlock]

  @spec process_ast(ast(), keyword()) :: ast()
  def process_ast(ast, opts \\ []) when is_list(ast) do
    stages = Keyword.get(opts, :stages, @compile_stages)

    # Stages never fail soft today (CodeBlock degrades internally); a stage
    # error here is a bug and should halt compilation loudly.
    {:ok, processed} = Pipeline.process(ast, Keyword.put(opts, :stages, stages))
    processed
  end

  @doc """
  Renders an AST into HTML format.

  ## Parameters
    - ast: The AST to render
    - opts: Options for rendering

  ## Returns
    - The rendered HTML as a string
  """
  @spec render_ast(ast(), keyword()) :: String.t()
  def render_ast(ast, _opts \\ []) when is_list(ast) do
    # We need to convert the AST to HTML for proper rendering
    Renderer.render_html(ast)
  end

  @doc """
  Compiles content with optional translations.

  This function handles the full compilation pipeline:
  1. Parsing the content to AST
  2. Applying any necessary transformations
  3. Compiling with translations if requested

  ## Parameters
    - content: The raw content to compile
    - opts: Options including locale, translations handling

  ## Returns
    - A tuple with the result: `{:ok, result}` or `{:error, reason}`
    - The result contains the AST and compiled HTML content
  """
  @spec compile(String.t() | nil, keyword()) ::
          {:ok, %{ast: ast(), compiled_content: String.t()}}
          | {:error, any()}
  def compile(content, opts \\ [])

  def compile(nil, _opts) do
    {:error, "Cannot compile nil content"}
  end

  def compile(content, opts) when is_binary(content) do
    case parse_to_ast(content) do
      {:ok, ast} ->
        processed_ast = process_ast(ast, opts)
        # Generate HTML but keep the AST as the primary output
        compiled_content = render_ast(processed_ast, opts)

        {:ok,
         %{
           ast: processed_ast,
           compiled_content: compiled_content
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Compiles content in multiple languages using available translations.

  ## Parameters
    - content_entry: The content entry (e.g., Note or CaseStudy)
    - opts: Options for compilation

  ## Returns
    - A tuple with the result: `{:ok, result}` or `{:error, reason}`
    - The result contains the compiled content for each language
  """
  @spec compile_translations(any(), keyword()) ::
          {:ok, %{translations: map(), primary_ast: ast()}}
          | {:error, any()}
  def compile_translations(content_entry, opts \\ []) do
    content_id = content_entry.id
    content_type = content_entry.__struct__.translatable_type()

    # Get all translations for this content (for all locales)
    all_translations = get_all_translations(content_id, content_type)

    # Group translations by locale correctly, only use Translation structs
    translations_by_locale =
      all_translations
      |> Enum.filter(&is_struct(&1, Translation))
      |> Enum.group_by(& &1.locale)

    # Get content's original locale
    original_locale = content_entry.locale || "en"

    # Parse primary content to AST
    case parse_to_ast(content_entry.content) do
      {:ok, primary_ast} ->
        # Process the primary AST
        processed_primary_ast = process_ast(primary_ast, opts)

        # Create a map to hold compiled content for each locale
        compiled_locales =
          compile_for_locales(
            processed_primary_ast,
            content_entry,
            translations_by_locale,
            original_locale
          )

        {:ok,
         %{
           translations: compiled_locales,
           primary_ast: processed_primary_ast
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Helper to get all translations for a content entry
  defp get_all_translations(content_id, content_type) do
    # Collect translations for all available locales
    locales = LanguageUtils.available_locales()

    # Use flat_map to iterate through locales and collect results from the helper
    Enum.flat_map(locales, fn locale ->
      # Delegate all logic for fetching and structuring translations for the locale to the helper
      fetch_and_structure_translations_for_locale(
        content_id,
        content_type,
        locale
      )

      # flat_map will automatically handle the empty lists returned by the helper for locales with no translations
    end)
  end

  # Helper to fetch and structure translations for a single locale
  # Returns a list of Translation structs or an empty list.
  defp fetch_and_structure_translations_for_locale(
         content_id,
         content_type,
         locale
       ) do
    # Fetch the raw translation map for the given locale
    trans_map =
      TranslationRepository.get_translations(content_id, content_type, locale)

    # Check if the map is not empty
    if map_size(trans_map) > 0 do
      # Convert the map to a list of Translation structs
      Enum.map(trans_map, fn {field_name, field_value} ->
        %Translation{
          translatable_id: content_id,
          translatable_type: content_type,
          locale: locale,
          field_name: field_name,
          field_value: field_value
        }
      end)
    else
      # Return an empty list if no translations were found for this locale
      []
    end
  end

  # Helper function to compile content for each locale
  defp compile_for_locales(
         primary_ast,
         content_entry,
         translations_by_locale,
         original_locale
       ) do
    available_locales = LanguageUtils.available_locales()

    available_locales
    |> Stream.map(fn locale ->
      # Calculate the result tuple {:ok, data} or {:error, reason} for each locale
      result_tuple =
        if locale == original_locale do
          # Original locale logic
          compiled_content = render_ast(primary_ast)

          {:ok,
           %{
             compiled_content: compiled_content,
             ast: primary_ast,
             source: :original
           }}
        else
          # Translated locale logic - relies on compile_for_translation
          compile_for_translation(
            primary_ast,
            content_entry,
            translations_by_locale,
            locale
          )
        end

      # Return locale paired with its result tuple
      {locale, result_tuple}
    end)
    |> Stream.filter(fn {_locale, result_tuple} ->
      # Keep only entries where the compilation was successful
      match?({:ok, _}, result_tuple)
    end)
    |> Enum.into(%{}, fn {locale, {:ok, result}} ->
      # Build the final map {locale => result_map}
      {locale, result}
    end)
  end

  # Helper to compile content for a specific translation
  defp compile_for_translation(
         primary_ast,
         content_entry,
         translations_by_locale,
         locale
       ) do
    # Get translations for this locale
    locale_translations = Map.get(translations_by_locale, locale, [])

    if locale_translations == [] do
      # No translations for this locale
      {:error, :no_translations}
    else
      # Create a translated version of content using translations
      translated_content =
        create_translated_content(content_entry, locale_translations)

      # Process fields through AST pipeline if they're markdown
      processed_translated_content =
        process_translated_content(translated_content, primary_ast)

      # Render HTML from the translated AST, but keep the AST too
      compiled_content =
        render_ast(primary_ast, translated_fields: translated_content)

      {:ok,
       %{
         compiled_content: compiled_content,
         ast: processed_translated_content,
         source: :translation
       }}
    end
  end

  # Process translated content fields that need AST parsing
  defp process_translated_content(translated_content, _primary_ast) do
    # Use Map.new for a functional transformation
    Map.new(translated_content, fn {key, value} ->
      # Delegate processing of each field to the multi-head helper
      processed_value = process_single_translation_field(key, value)
      # Return the {key, processed_value} tuple for Map.new
      {key, processed_value}
    end)
  end

  # Helper function using pattern matching on the key

  # Head specifically for the "content" key when value is binary
  defp process_single_translation_field("content", value)
       when is_binary(value) do
    # Logic specifically for the "content" field: parse and process AST
    case parse_to_ast(value) do
      # Return processed AST
      {:ok, ast} -> process_ast(ast)
      # Return original value on parse error
      _ -> value
    end
  end

  # Catch-all head for any other key or non-binary "content" value
  defp process_single_translation_field(_key, value) do
    # Logic for all other fields: keep value as-is
    value
  end

  # Create a map of translated fields from the translations
  defp create_translated_content(content_entry, translations) do
    # Start with the original content as the base
    base_content = %{
      "title" => content_entry.title,
      "content" => content_entry.content
    }

    # Apply each translation
    Enum.reduce(translations, base_content, fn %Translation{
                                                 field_name: field,
                                                 field_value: value
                                               },
                                               acc ->
      Map.put(acc, field, value)
    end)
  end

  @doc """
  Deserializes stored AST from the database and processes it for rendering.

  ## Parameters
    - stored_ast: The serialized AST from the database
    - opts: Options for processing

  ## Returns
    - The deserialized and processed AST
  """
  @spec deserialize_and_process_ast(map() | list() | nil, keyword()) :: ast()
  def deserialize_and_process_ast(stored_ast, opts \\ [])

  def deserialize_and_process_ast(nil, _opts) do
    []
  end

  def deserialize_and_process_ast(stored_ast, opts) do
    deserialized_ast = AstSerialization.deserialize_ast(stored_ast)
    process_ast(deserialized_ast, opts)
  end
end
