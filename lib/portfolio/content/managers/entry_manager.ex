defmodule Portfolio.Content.EntryManager do
  @moduledoc """
  Manages the lifecycle of content entries in the Portfolio application.

  This module handles creating, updating, deleting, and retrieving content entries
  such as Notes and Case Studies. It serves as an intermediary between the database
  and application logic, coordinating with TranslationManager for non-default locales.

  Note: This module is being refactored into smaller, more focused modules:
  - Records: Core database operations
  - Compiler: Content compilation and AST management
  - Source: File-based operations
  - Translations: Translation coordination
  """
  alias Portfolio.Repo
  alias Portfolio.Content.Types
  alias Portfolio.Content.Schemas.{Note, CaseStudy}
  alias Portfolio.Content.Managers.Entry.Compiler
  alias Portfolio.Content.Managers.Entry.Records
  alias Portfolio.Content.Managers.Entry.Source
  alias Portfolio.Content.Managers.Entry.Translations

  require Logger

  @type content_type :: Types.content_type()

  @doc """
  Creates a new content entry.

  ## Parameters

    * `attrs` - A map containing the attributes for the new content entry.

  ## Returns

    * `{:ok, content}` if the content was successfully created.
    * `{:error, reason}` if there was an error during creation.
  """
  @spec create_content(map()) ::
          {:ok, Note.t() | CaseStudy.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, :invalid_content_type}
          | {:error, any()}
  def create_content(attrs) do
    Logger.debug("Create content called with attrs: #{inspect(attrs)}")

    case get_schema(attrs["content_type"]) do
      {:error, :invalid_content_type} = error ->
        error

      {:ok, schema} ->
        with changeset <- apply_changeset(struct(schema), attrs),
             {:ok, content} <- Records.insert_content(changeset),
             {:ok, %{ast: ast}} <- Compiler.compile(content.content),
             {:ok, updated_content} <- Records.update_stored_ast(content, ast) do
          {:ok, updated_content}
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc """
  Updates an existing content entry.

  ## Parameters

    * `content` - The existing content entry to update.
    * `attrs` - A map containing the updated attributes.
    * `content_type` - The type of the content being updated.

  ## Returns

    * `{:ok, content}` if the content was successfully updated.
    * `{:error, reason}` if there was an error during update.
  """
  @spec update_content(Note.t() | CaseStudy.t(), map(), content_type()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, any()}
  def update_content(content, attrs, content_type) do
    # Start a transaction
    Repo.transaction(fn ->
      # Update basic attributes first
      with {:ok, content} <- Records.update_content_attributes(content, attrs),
           # Then handle content compilation if content was updated
           {:ok, content} <- maybe_compile_updated_content(content, attrs) do
        content
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  # Only compile content if it has changed
  defp maybe_compile_updated_content(content, %{content: new_content})
       when is_binary(new_content) do
    # Compile the new content and get the AST
    with {:ok, %{ast: ast}} <- Compiler.compile(new_content) do
      # Update with stored AST
      Records.update_stored_ast(content, ast)
    end
  end

  # If content wasn't updated, return content as is
  defp maybe_compile_updated_content(content, _attrs), do: {:ok, content}

  @doc """
  Deletes a content entry.

  ## Parameters

    * `content` - The content entry to delete.

  ## Returns

    * `{:ok, content}` if the content was successfully deleted.
    * `{:error, changeset}` if there was an error during deletion.
  """
  @spec delete_content(Note.t() | CaseStudy.t()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  def delete_content(content) do
    Records.delete_content(content)
  end

  @doc """
  Retrieves content by ID or URL.

  ## Parameters
    - content_type: String representing the type of content ("note" or "case_study")
    - id_or_url: Integer ID or String URL of the content

  ## Returns
    - The content struct if found

  ## Raises
    - Ecto.NoResultsError if no content is found
  """
  @spec get_content_by_id_or_url(content_type(), integer() | String.t()) ::
          Note.t() | CaseStudy.t()
  def get_content_by_id_or_url(content_type, id_or_url) do
    # Delegate to Records module
    content = Records.get_content_by_id_or_url(content_type, id_or_url)

    # Compile content to HTML for display
    case Compiler.compile(content.content) do
      {:ok, %{compiled_content: html}} ->
        %{content | compiled_content: html}

      _ ->
        content
    end
  end

  @doc """
  Fetches content items based on translatable IDs and type.

  ## Parameters
    - translatable_ids: List of content IDs
    - type: String representing the type of content ("note" or "case_study")

  ## Returns
    - {:ok, list of content items}

  ## Raises
    - Ecto.NoResultsError if no content is found
  """
  @spec fetch_content_items([binary()], String.t()) ::
          {:ok, [Note.t()] | [CaseStudy.t()]}
  def fetch_content_items(translatable_ids, type) do
    Records.fetch_content_items(translatable_ids, type)
  end

  @doc """
  Lists content items of a specific type with optional sorting and locale.

  ## Parameters
    - type: The content type ("note" or "case_study")
    - opts: Keyword list of options (e.g., [sort_by: :published_at, sort_order: :desc])
    - locale: The locale for translations (default: @default_locale)

  ## Returns
    - List of content items with merged translations
  """
  @spec list_contents(Types.content_type(), keyword(), String.t()) ::
          [Note.t()] | [CaseStudy.t()]
  def list_contents(content_type, opts \\ [], locale \\ "en") do
    # Delegate to Translations module
    Translations.list_with_translations(content_type, opts, locale)
  end

  ##########################################
  # Handle Translations                    #
  ##########################################

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
  @spec get_content_with_translations(
          Types.content_type(),
          String.t() | integer(),
          String.t()
        ) ::
          {:ok, Note.t() | CaseStudy.t(), map(), list()} | {:error, atom()}
  def get_content_with_translations(content_type, id_or_url, locale) do
    # Delegate to Translations module
    Translations.get_with_compiled_translations(content_type, id_or_url, locale)
  end

  ##########################################
  # Updates from the markdown file changes #
  ##########################################

  @doc """
  Upserts content from file attributes, considering both URL and locale.

  For the default locale, it creates or updates the main content entry.
  For non-default locales, it creates or updates translations.

  ## Parameters
    - content_type: String representing the type of content ("note" or "case_study")
    - attrs: Map of attributes including "url", "locale", and other content fields

  ## Returns
    - {:ok, content} if the operation was successful
    - {:error, changeset} if there was an error
  """
  @spec upsert_from_file(content_type() | atom(), map()) ::
          {:ok, Note.t() | CaseStudy.t()}
          | {:error, atom() | Ecto.Changeset.t()}
  def upsert_from_file(content_type, attrs) do
    # Delegate to Source module
    Source.upsert_from_file(content_type, attrs)
  end

  # Helpers that are still needed

  defp get_schema(content_type) do
    case Types.get_schema(content_type) do
      {:error, :invalid_content_type} = error -> error
      schema -> {:ok, schema}
    end
  end

  defp apply_changeset(%Note{} = note, attrs), do: Note.changeset(note, attrs)

  defp apply_changeset(%CaseStudy{} = case_study, attrs),
    do: CaseStudy.changeset(case_study, attrs)
end
