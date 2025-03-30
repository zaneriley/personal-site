defmodule Portfolio.Content.Entry.Source do
  @moduledoc """
  Handles file-based operations for content entries.

  This module is responsible for upserting content entries from file attributes,
  considering both URL and locale. It coordinates with Records for database operations,
  Compiler for AST generation, and TranslationManager for translations.
  """

  alias Portfolio.Repo
  alias Portfolio.Content.Types
  alias Portfolio.Content.Schemas.{Note, CaseStudy}
  alias Portfolio.Content.TranslationManager
  alias Portfolio.Content.Entry.Compiler
  alias Portfolio.Content.Entry.Records

  require Logger

  @default_locale Application.compile_env(:portfolio, :default_locale)
  @type content_type :: Types.content_type()

  @doc """
  Upserts content from file attributes, considering both URL and locale.

  For the default locale, it creates or updates the main content entry.
  For non-default locales, it creates or updates translations.

  ## Parameters
    - content_type: An atom or string representing the type of content ("note" or "case_study")
    - attrs: Map of attributes including "url", "locale", and other content fields

  ## Returns
    - {:ok, content} if the operation was successful
    - {:error, changeset} if there was an error
  """
  @spec upsert_from_file(content_type() | String.t(), map()) ::
          {:ok, Note.t() | CaseStudy.t()}
          | {:error, atom() | Ecto.Changeset.t()}
  def upsert_from_file(content_type, attrs) when is_atom(content_type) do
    upsert_from_file(Atom.to_string(content_type), attrs)
  end

  def upsert_from_file(content_type, attrs) when is_binary(content_type) do
    with {:ok, schema} <- get_schema(content_type),
         {:ok, content} <- upsert_content(schema, attrs, content_type),
         # Get the AST from compiler
         {:ok, %{ast: ast}} <- Compiler.compile(content.content),
         # Store the AST in the database
         {:ok, updated_content} <- Records.update_stored_ast(content, ast) do
      # Return the content with AST
      {:ok, updated_content}
    else
      {:error, reason} ->
        Logger.error("Error in upsert_from_file: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Helper to get the schema for a content type
  defp get_schema(content_type) do
    case Types.get_schema(content_type) do
      {:error, :invalid_content_type} = error -> error
      schema -> {:ok, schema}
    end
  end

  # Choose between default and non-default locale handling
  defp upsert_content(schema, attrs, content_type) do
    if attrs["locale"] == @default_locale do
      upsert_default_locale_content(schema, attrs, content_type)
    else
      upsert_non_default_locale_content(schema, attrs, content_type)
    end
  end

  # Handle content for the default locale
  defp upsert_default_locale_content(schema, attrs, content_type) do
    Logger.info(
      "Upserting default locale content with URL: #{inspect(attrs["url"])}"
    )

    if is_nil(attrs["url"]) do
      Logger.error("URL is nil in attrs: #{inspect(attrs)}")
      {:error, :nil_url}
    else
      case Repo.get_by(schema, url: attrs["url"]) do
        nil ->
          Logger.info("Creating new content for URL: #{attrs["url"]}")
          create_content(Map.put(attrs, "content_type", content_type))

        entry ->
          Logger.info("Updating existing content for URL: #{attrs["url"]}")
          update_content(entry, attrs, content_type)
      end
    end
  end

  # Handle content for non-default locales
  defp upsert_non_default_locale_content(schema, attrs, content_type) do
    case Repo.get_by(schema, url: attrs["url"]) do
      nil -> create_entry_with_translations(attrs, content_type)
      entry -> update_entry_translations(entry, attrs)
    end
  end

  # Create new content entry with translations
  defp create_entry_with_translations(attrs, content_type) do
    with {:ok, entry} <-
           create_content(Map.put(attrs, "content_type", content_type)),
         {:ok, _translations} <- create_or_update_translations(entry, attrs) do
      {:ok, entry}
    end
  end

  # Update existing entry's translations
  defp update_entry_translations(entry, attrs) do
    case create_or_update_translations(entry, attrs) do
      {:ok, _translations} -> {:ok, entry}
      error -> error
    end
  end

  # Create or update translations for an entry
  defp create_or_update_translations(entry, attrs) do
    TranslationManager.create_or_update_translations(
      entry,
      attrs["locale"],
      attrs
    )
  end

  # Create a new content entry
  defp create_content(attrs) do
    case get_schema(attrs["content_type"]) do
      {:error, :invalid_content_type} = error ->
        error

      {:ok, schema} ->
        with changeset <- apply_changeset(struct(schema), attrs),
             {:ok, content} <- Records.insert_content(changeset),
             # Get AST from compiler
             {:ok, %{ast: ast}} <- Compiler.compile(content.content),
             # Store the AST in the database
             {:ok, updated_content} <- Records.update_stored_ast(content, ast) do
          {:ok, updated_content}
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end

  # Update an existing content entry
  defp update_content(content, attrs, content_type) do
    # Start a transaction
    Repo.transaction(fn ->
      # Update basic attributes first
      with {:ok, content} <- Records.update_content_attributes(content, attrs),
           # Then handle content compilation if content was updated
           {:ok, content} <- compile_updated_content(content, attrs) do
        content
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  # Compile updated content if it has changed
  defp compile_updated_content(content, %{content: new_content})
       when is_binary(new_content) do
    # Compile the new content and get the AST
    with {:ok, %{ast: ast}} <- Compiler.compile(new_content) do
      # Update with stored AST
      Records.update_stored_ast(content, ast)
    end
  end

  # If content wasn't updated, return content as is
  defp compile_updated_content(content, _attrs), do: {:ok, content}

  # Apply the appropriate changeset for the content type
  defp apply_changeset(%Note{} = note, attrs), do: Note.changeset(note, attrs)

  defp apply_changeset(%CaseStudy{} = case_study, attrs),
    do: CaseStudy.changeset(case_study, attrs)
end
