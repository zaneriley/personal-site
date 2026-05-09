defmodule Portfolio.Content.EntryAssembler do
  @moduledoc """
  Handles translation-related operations for content entries.

  This module is responsible for coordinating between Records, Compiler, and TranslationRepository
  to retrieve content with its translations and to process them for display.
  """

  alias Portfolio.Content.Entry.Compiler
  alias Portfolio.Content.Entry.Records
  alias Portfolio.Content.Schemas.CaseStudy
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Content.TranslationRepository
  alias Portfolio.Content.Types

  require Logger

  @type content_type :: Types.content_type()

  @doc """
  Retrieves content with its translations for a specific locale.

  ## Parameters
    - content_type: The type of content ("note" or "case_study")
    - id_or_url: Integer ID or String URL of the content
    - locale: The locale for translations

  ## Returns
    - {:ok, content, translations, ast} if successful
    - {:error, reason} if there was an error
  """
  @spec get_assembled_entry(
          content_type(),
          String.t() | integer(),
          String.t()
        ) ::
          {:ok, Note.t() | CaseStudy.t(), map(), list()} | {:error, atom()}
  def get_assembled_entry(content_type, id_or_url, locale) do
    Logger.debug(
      "Fetching #{content_type} with translations for locale: #{locale}"
    )

    try do
      # Get the content from the database
      content = Records.get_content_by_id_or_url(content_type, id_or_url)

      # Get translations for this content and locale
      translations =
        TranslationRepository.get_translations(content.id, content_type, locale)

      # Determine which fields are markdown fields
      schema = content.__struct__
      markdown_fields = schema.markdown_fields()

      # Process content and translations
      with {:ok, %{ast: ast}} <- Compiler.compile(content.content),
           {:ok, compiled_translations} <-
             compile_translations(translations, content_type, markdown_fields) do
        # Set compiled_content to nil to indicate we're using AST
        updated_content = %{content | compiled_content: nil}
        # Return the AST as the fourth element
        {:ok, updated_content, compiled_translations, ast}
      else
        {:error, reason} ->
          Logger.error(
            "Failed to compile content or translations: #{inspect(reason)}"
          )

          {:error, :compilation_failed}
      end
    rescue
      Ecto.NoResultsError ->
        Logger.warning(
          "No #{content_type} found for identifier: #{inspect(id_or_url)}"
        )

        {:error, :not_found}
    end
  end

  @doc """
  Lists content with translations for a specific locale.

  ## Parameters
    - content_type: The type of content ("note" or "case_study")
    - opts: Options for sorting and filtering
    - locale: The locale for translations

  ## Returns
    - List of content items with merged translations
  """
  @spec list_assembled_entries(content_type(), keyword(), String.t()) ::
          [Note.t()] | [CaseStudy.t()]
  def list_assembled_entries(content_type, opts \\ [], locale \\ "en") do
    # Get base content items
    contents = Records.list_contents(content_type, opts)

    # Extract content IDs for batch translation retrieval
    content_ids = Enum.map(contents, & &1.id)

    # Get translations for all content items in the specified locale
    translations =
      TranslationRepository.batch_get_translations(
        content_ids,
        content_type,
        locale
      )

    Logger.debug("Fetched translations: #{inspect(translations)}")

    # Merge translations with content items
    result =
      Enum.map(contents, fn content ->
        content_translations = Map.get(translations, content.id, %{})

        Logger.debug(
          "Translations for content: #{inspect(content_translations)}"
        )

        # Add translations to the content item
        merged_content = Map.put(content, :translations, content_translations)
        merged_content
      end)

    result
  end

  # Helper function to compile translations
  defp compile_translations(translations, _content_type, markdown_fields) do
    Enum.reduce_while(translations, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
      is_markdown = to_string(key) in markdown_fields

      if is_markdown do
        # Delegate markdown processing to the helper function
        process_markdown_translation(key, value, acc)
      else
        # Non-markdown fields: directly put the value
        {:cont, {:ok, Map.put(acc, key, value)}}
      end
    end)
  end

  # Handles the compilation logic for a single markdown translation field
  defp process_markdown_translation(key, value, acc) do
    case Compiler.compile(value) do
      {:ok, %{ast: ast}} ->
        # Compilation successful, store the AST
        {:cont, {:ok, Map.put(acc, key, ast)}}

      {:error, reason} ->
        # Compilation failed, log the error and halt the reduction
        Logger.error(
          "Error compiling translation for key: #{key}. Error: #{inspect(reason)}"
        )

        {:halt, {:error, reason}}
    end
  end
end
