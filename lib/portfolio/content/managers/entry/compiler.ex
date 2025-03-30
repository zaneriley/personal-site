defmodule Portfolio.Content.Managers.Entry.Compiler do
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
  alias Portfolio.Content.Markdown.Renderer
  alias Portfolio.Content.Managers.Entry.AstSerialization
  alias Portfolio.Content.Schemas.Translation
  alias Portfolio.Content.TranslationManager
  alias Portfolio.Content.Utils.LanguageUtils

  require Logger

  @doc """
  Parses raw markdown content into an AST representation.

  ## Parameters
    - content: The raw markdown content to parse

  ## Returns
    - A tuple with the result and AST: `{:ok, ast}` or `{:error, reason}`
  """
  @spec parse_to_ast(String.t() | nil) :: {:ok, list()} | {:error, any()}
  def parse_to_ast(nil) do
    {:error, "Cannot parse nil content"}
  end

  def parse_to_ast(content) when is_binary(content) do
    try do
      result = Parser.parse(content)

      # Parser.parse returns a complex structure, try to extract AST
      ast = extract_ast_from_parser_result(result)

      {:ok, ast}
    rescue
      e ->
        Logger.error("Error parsing content to AST: #{inspect(e)}")
        {:error, "Failed to parse content"}
    end
  end

  # Extract AST from various parser result formats
  defp extract_ast_from_parser_result({:ok, %{ast: ast}}) do
    ast
  end

  defp extract_ast_from_parser_result(%{ast: ast}) do
    ast
  end

  defp extract_ast_from_parser_result(ast) when is_list(ast) do
    ast
  end

  defp extract_ast_from_parser_result(other) do
    Logger.error("Unexpected parser result format: #{inspect(other)}")
    # Return an empty list as a fallback
    []
  end

  @doc """
  Processes an AST with various transformations to prepare it for rendering.

  ## Parameters
    - ast: The AST to process
    - opts: Options for processing (e.g., locale, transforms)

  ## Returns
    - The processed AST
  """
  @spec process_ast(list(), keyword()) :: list()
  def process_ast(ast, _opts \\ []) when is_list(ast) do
    # Apply transforms like syntax highlighting, image processing, etc.
    # This is a simple pass-through for now as we migrate functionality
    ast
  end

  @doc """
  Renders an AST into HTML format.

  ## Parameters
    - ast: The AST to render
    - opts: Options for rendering

  ## Returns
    - The rendered HTML as a string
  """
  @spec render_ast(list(), keyword()) :: String.t()
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
          {:ok, %{ast: list(), compiled_content: String.t()}}
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
          {:ok, %{translations: map(), primary_ast: list()}}
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

    Enum.flat_map(locales, fn locale ->
      trans =
        TranslationManager.get_translations(content_id, content_type, locale)

      if map_size(trans) > 0 do
        # Convert the map to Translation structs
        Enum.map(trans, fn {field_name, field_value} ->
          %Translation{
            translatable_id: content_id,
            translatable_type: content_type,
            locale: locale,
            field_name: field_name,
            field_value: field_value
          }
        end)
      else
        []
      end
    end)
  end

  # Helper function to compile content for each locale
  defp compile_for_locales(
         primary_ast,
         content_entry,
         translations_by_locale,
         original_locale
       ) do
    available_locales = LanguageUtils.available_locales()

    # Compile for each available locale
    Enum.reduce(available_locales, %{}, fn locale, acc ->
      # For original locale, use the original content
      if locale == original_locale do
        # Generate HTML but preserve original AST
        compiled_content = render_ast(primary_ast)

        Map.put(acc, locale, %{
          compiled_content: compiled_content,
          ast: primary_ast,
          source: :original
        })
      else
        # For other locales, use translations if available
        case compile_for_translation(
               primary_ast,
               content_entry,
               translations_by_locale,
               locale
             ) do
          {:ok, result} ->
            Map.put(acc, locale, result)

          _ ->
            acc
        end
      end
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
    # For now, a simple implementation that preserves the AST structure
    # More complex processing can be added here as needed
    Enum.reduce(translated_content, %{}, fn {key, value}, acc ->
      case key do
        "content" when is_binary(value) ->
          # Parse "content" field to AST if it's markdown
          case parse_to_ast(value) do
            {:ok, ast} -> Map.put(acc, key, process_ast(ast))
            _ -> Map.put(acc, key, value)
          end

        _ ->
          # Keep other fields as-is
          Map.put(acc, key, value)
      end
    end)
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
  @spec deserialize_and_process_ast(map() | list() | nil, keyword()) :: list()
  def deserialize_and_process_ast(stored_ast, opts \\ [])

  def deserialize_and_process_ast(nil, _opts) do
    []
  end

  def deserialize_and_process_ast(stored_ast, opts) do
    deserialized_ast = AstSerialization.deserialize_ast(stored_ast)
    process_ast(deserialized_ast, opts)
  end
end
