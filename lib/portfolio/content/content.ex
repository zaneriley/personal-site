defmodule Portfolio.Content do
  @moduledoc """
  The primary interface for managing content entries within the Portfolio application.

  This context module acts as a facade, providing a consistent API for interacting
  with different types of content, primarily `Note` and `CaseStudy` records.
  It orchestrates operations across specialized sub-modules responsible for
  database interactions (`Records`), content compilation (`Compiler`), data assembly
  (`EntryAssembler`), file-based ingestion (`Source`), and translation management
  (`TranslationManager`).

  ## Core Responsibilities

  *   **Abstraction:** Hides the complexity of the underlying storage, compilation,
      and translation mechanisms.
  *   **Consistency:** Offers a unified way to handle different content types.
  *   **Data Integrity:** Ensures required fields and basic validations are met
      during create/update operations via changesets.

  ## Key Functions

  This module provides functions to:

  *   **List Content:**
      *   `list/3`: Retrieve lists of published `Note` or `CaseStudy` items,
          optionally sorted and localized with merged translation data.
          (`list(content_type, opts \\ [], locale \\ nil)`)

  *   **Retrieve Content:**
      *   `get!/2`: Fetch a single `Note` or `CaseStudy` by its ID or URL slug.
          Returns the content struct (with `compiled_content` often containing
          the processed AST) or raises `Ecto.NoResultsError` if not found,
          or `Portfolio.Content.InvalidContentTypeError` for bad types.
          (`get!(content_type, id_or_url)`)
      *   `get_with_translations/3`: Fetch a single content item along with its
          translations for a specific locale and its primary AST. Returns
          `{:ok, content, translations_map, ast}` or `{:error, reason}`.
          (`get_with_translations(content_type, id_or_url, locale)`)

  *   **Modify Content:**
      *   `create/2`: Create a new `Note` or `CaseStudy` from attributes. Returns
          `{:ok, content}` or `{:error, changeset | reason}`.
          (`create(content_type, attrs)`)
      *   `update/3`: Update an existing `Note` or `CaseStudy`. Returns
          `{:ok, content}` or `{:error, changeset | reason}`.
          (`update(content_type, content_struct, attrs)`)
      *   `delete/2`: Delete a `Note` or `CaseStudy`. Returns `{:ok, content}` or
          `{:error, changeset}`.
          (`delete(content_type, content_struct)`)
      *   `change/3`: Generate an `Ecto.Changeset` for a `Note` or `CaseStudy`,
          useful for forms. Returns `changeset` or `{:error, :invalid_content_type}`.
          (`change(content_type, content_struct_or_map, attrs \\ %{})`)

  *   **File-Based Operations:**
      *   `upsert_from_file/2`: Create or update content based on attributes derived
          from a file, handling default locale content and translations for other locales.
          (`upsert_from_file(content_type, attrs)`)
      *   `extract_locale/1`: Helper to determine the locale from a content file path.
          (`extract_locale(file_path)`)

  ## Content Types

  Functions typically require a `content_type` argument, which should be one of the
  atoms or strings defined in `Portfolio.Content.Types` (e.g., `"note"`, `:note`,
  `"case_study"`, `:case_study`).

  ## Translations

  Functions like `list/3` and `get_with_translations/3` automatically handle
  fetching and merging translated fields based on the specified locale. The underlying
  `TranslationManager` handles storage.

  ## AST vs Compiled Content

  Note that this context often works with Abstract Syntax Trees (AST) for content
  representation, especially after recent refactoring. Functions returning content
  may place the processed AST in the `:compiled_content` field (or return it separately
  as in `get_with_translations`) rather than pre-rendered HTML, facilitating flexible
  rendering in components.
  """
  alias Portfolio.Content.Entry.Compiler
  alias Portfolio.Content.Entry.Records
  alias Portfolio.Content.Entry.Source
  alias Portfolio.Content.EntryAssembler
  alias Portfolio.Content.Schemas.CaseStudy
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Content.Schemas.PublicationVerdict
  alias Portfolio.Content.Types
  alias Portfolio.Repo

  require Logger

  defmodule InvalidContentTypeError do
    defexception [:message]
  end

  @type content_type :: Types.content_type()
  @type content_id :: Ecto.UUID.t()
  @type content_url :: String.t()
  @type content_identifier :: content_id() | content_url()
  @type publication_verdict_status ::
          :accepted | :rejected | :ignored | String.t()

  @doc """
  Records the publishing verdict for a content repository commit.

  The latest verdict for a commit SHA replaces any prior verdict for that SHA,
  which makes webhook retries idempotent from the author-facing status view.
  """
  @spec record_publication_verdict(
          String.t(),
          publication_verdict_status(),
          keyword()
        ) ::
          {:ok, PublicationVerdict.t()} | {:error, Ecto.Changeset.t()}
  def record_publication_verdict(content_sha, status, opts \\ [])
      when is_binary(content_sha) do
    attrs = %{
      content_sha: content_sha,
      status: normalize_publication_status(status),
      reason: Keyword.get(opts, :reason),
      promoted_paths: Keyword.get(opts, :promoted_paths, []),
      removed_paths: Keyword.get(opts, :removed_paths, []),
      skipped_paths: Keyword.get(opts, :skipped_paths, []),
      error_details: Keyword.get(opts, :error_details, %{})
    }

    %PublicationVerdict{}
    |> PublicationVerdict.changeset(attrs)
    |> Repo.insert(
      on_conflict:
        {:replace,
         [
           :status,
           :reason,
           :promoted_paths,
           :removed_paths,
           :skipped_paths,
           :error_details,
           :updated_at
         ]},
      conflict_target: :content_sha,
      returning: true
    )
  end

  @doc """
  Fetches the publishing verdict recorded for a content repository commit.
  """
  @spec get_publication_verdict(String.t()) :: PublicationVerdict.t() | nil
  def get_publication_verdict(content_sha) when is_binary(content_sha) do
    Repo.get_by(PublicationVerdict, content_sha: content_sha)
  end

  @doc """
  Lists content items of a specific type with optional sorting and locale.

  ## Parameters
    - type: The content type ("note" or "case_study")
    - opts: Keyword list of options (e.g., [sort_by: :published_at, sort_order: :desc])
    - locale: The locale for translations (optional)

  ## Returns
    - List of content items with merged translations
  """
  @spec list(content_type(), keyword(), String.t() | nil) ::
          [Note.t()] | [CaseStudy.t()]
  def list(type, opts \\ [], locale \\ nil) do
    locale = locale || Application.get_env(:portfolio, :default_locale)
    EntryAssembler.list_assembled_entries(type, opts, locale)
  end

  @doc """
  Retrieves a content item (Note or CaseStudy) by its type and identifier.

  ## Parameters
    - type: The content type ("note" or "case_study")
    - id_or_url: The unique identifier (ID or URL) of the content item

  ## Returns
    - The content item (Note or CaseStudy) if found

  ## Raises
    - Ecto.NoResultsError: If no content is found
    - InvalidContentTypeError: If an invalid content type is provided

  ## Examples

      iex> Content.get!("note", "my-note-url")
      %Note{...}

      iex> Content.get!("case_study", "non-existent-id")
      ** (Ecto.NoResultsError)

      iex> Content.get!("invalid_type", "some-id")
      ** (InvalidContentTypeError)
  """
  @spec get!(content_type(), content_identifier()) ::
          Note.t() | CaseStudy.t() | no_return()
  def get!(type, id_or_url) do
    Logger.debug(
      "Attempting to fetch #{type} with identifier: #{inspect(id_or_url)}"
    )

    case Types.valid_type?(type) do
      true ->
        fetch_content(type, id_or_url)

      false ->
        Logger.error("Invalid content type provided: #{inspect(type)}")
        raise InvalidContentTypeError, "Invalid content type: #{inspect(type)}"
    end
  end

  @spec fetch_content(content_type(), content_identifier()) ::
          Note.t() | CaseStudy.t() | no_return()
  defp fetch_content(type, id_or_url) do
    # Fetch content directly from Records
    content = Records.get_content_by_id_or_url(type, id_or_url)

    # For our tests, we need to ensure compiled_content is always an AST list
    if content.stored_ast do
      ast = Compiler.deserialize_and_process_ast(content.stored_ast)
      %{content | compiled_content: ast}
    else
      # If no stored_ast, then compile the content to get an AST
      case Compiler.compile(content.content) do
        {:ok, %{ast: ast}} ->
          %{content | compiled_content: ast}

        _ ->
          # If all else fails, set compiled_content to an empty list
          %{content | compiled_content: []}
      end
    end
  end

  @spec create(content_type(), map()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, term()}
  def create(type, attrs) do
    Logger.debug(
      "Create called with type: #{inspect(type)}, attrs: #{inspect(attrs)}"
    )

    attrs = Map.put(attrs, "content_type", type)
    Logger.debug("Modified attrs: #{inspect(attrs)}")

    try do
      # Get the schema based on content type
      with {:ok, schema} <- Records.get_schema(attrs["content_type"]),
           # Apply changeset to the struct
           changeset <- Records.apply_changeset(struct(schema), attrs),
           # Insert the content
           {:ok, content} <- Records.insert_content(changeset),
           # Compile the content
           {:ok, %{ast: ast}} <- Compiler.compile(content.content) do
        # Update with the compiled AST
        Records.update_stored_ast(content, ast)
      end
    rescue
      Portfolio.Content.InvalidContentTypeError ->
        {:error, :invalid_content_type}
    end
  end

  @spec update(content_type(), Note.t() | CaseStudy.t(), map()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, term()}
  def update(_type, content, attrs) do
    # Use a transaction to ensure consistency
    result =
      Portfolio.Repo.transaction(fn ->
        # Use 'with' to chain the attribute update and the conditional compilation/AST update
        with {:ok, updated_content} <-
               Records.update_content_attributes(content, attrs),
             {:ok, final_content} <-
               compile_and_update_ast_if_changed(updated_content, attrs) do
          # If both steps succeed, return the final content struct
          final_content
        else
          # If either step returns an error, roll back the transaction
          {:error, reason} -> Portfolio.Repo.rollback(reason)
        end
      end)

    # For test compatibility, if update was successful, ensure content has AST in compiled_content
    case result do
      {:ok, updated_content} ->
        # Convert stored_ast to AST and set compiled_content for test compatibility
        if updated_content.stored_ast do
          ast = Compiler.deserialize_and_process_ast(updated_content.stored_ast)
          {:ok, %{updated_content | compiled_content: ast}}
        else
          result
        end

      error ->
        error
    end
  end

  # Helper function to compile and update AST if content changed
  defp compile_and_update_ast_if_changed(content, attrs) do
    # Check if the 'content' key exists in the attributes map (atom or string key)
    if Map.has_key?(attrs, :content) || Map.has_key?(attrs, "content") do
      content_value = attrs[:content] || attrs["content"]

      # Use 'with' for cleaner chaining of compilation and update steps
      with {:ok, %{ast: ast}} <- Compiler.compile(content_value),
           {:ok, content_with_ast} <- Records.update_stored_ast(content, ast) do
        # Return the content with updated AST on success
        {:ok, content_with_ast}
      else
        # Propagate errors from compile or update_stored_ast
        {:error, reason} -> {:error, reason}
      end
    else
      # No content change, operation is successful, return the original content struct
      {:ok, content}
    end
  end

  @spec delete(content_type(), Note.t() | CaseStudy.t()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  def delete(_type, content) do
    Records.delete_content(content)
  end

  @spec change(content_type(), Note.t() | CaseStudy.t() | map(), map()) ::
          Ecto.Changeset.t() | {:error, :invalid_content_type}
  def change(type, content, attrs \\ %{}) do
    Logger.debug("Content.change called with:")
    Logger.debug("  type: #{inspect(type)}")
    Logger.debug("  content: #{inspect(content)}")
    Logger.debug("  attrs: #{inspect(attrs)}")

    case Records.get_schema(type) do
      {:ok, schema} ->
        Logger.debug("Using schema: #{inspect(schema)}")

        # Use the appropriate struct for the changeset
        struct_to_use =
          if is_struct(content) do
            content
          else
            struct(schema)
          end

        # Apply the changeset
        changeset = Records.apply_changeset(struct_to_use, attrs)
        Logger.debug("Resulting changeset: #{inspect(changeset)}")
        changeset

      {:error, :invalid_content_type} ->
        Logger.error("Invalid content type: #{inspect(type)}")
        {:error, :invalid_content_type}
    end
  end

  @doc """
  Retrieves content with its translations and compiled content.

  ## Parameters
  - `content_type`: The type of content to retrieve ("note" or "case_study").
  - `identifier`: The unique identifier (URL or ID) of the content.
  - `locale`: The locale of the translations to fetch.

  ## Returns
  - `{:ok, content, translations, compiled_content}`: Content, its translations, and compiled content if found.
  - `{:error, :not_found}`: If no content is found.

  ## Examples

      iex> Content.get_with_translations("case_study", "my-case-study", "en")
      {:ok, %CaseStudy{...}, %{"title" => "Translated Title", ...}, "Translated Title"}

      iex> Content.get_with_translations("note", 123, "fr")
      {:ok, %Note{...}, %{"content" => "Contenu traduit", ...}, "<p>Contenu traduit</p>"}

      iex> Content.get_with_translations("case_study", "non-existent", "en")
      {:error, :not_found}
  """

  @spec get_with_translations(
          Types.content_type(),
          content_identifier(),
          String.t()
        ) ::
          {:ok, Note.t() | CaseStudy.t(), map(), EarmarkParser.ast()}
          | {:error, atom()}
  def get_with_translations(content_type, identifier, locale) do
    EntryAssembler.get_assembled_entry(content_type, identifier, locale)
  end

  @doc """
  Upserts content from a file based on the content type and attributes provided.

  This function delegates the actual upsert operation to Source.upsert_from_file
  after performing some basic logging. It handles both atom and string content types.

  ## Parameters
    - content_type: The type of content (e.g., :note, :case_study, "note", or "case_study").
    - attrs: Map of attributes to upsert the content with, including "url" and "locale".

  ## Returns
    - {:ok, content} if the content is successfully upserted
    - {:error, reason} if there is an error upserting the content

  ## Examples

      iex> Content.upsert_from_file(:note, %{"url" => "my-note", "locale" => "en", "title" => "My Note"})
      {:ok, %Note{...}}

      iex> Content.upsert_from_file("case_study", %{"url" => "my-case-study", "locale" => "fr", "title" => "Mon Étude de Cas"})
      {:ok, %CaseStudy{...}}
  """
  @spec upsert_from_file(atom() | String.t(), map()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, any()}
  def upsert_from_file(content_type, attrs) when is_atom(content_type) do
    upsert_from_file(Atom.to_string(content_type), attrs)
  end

  def upsert_from_file(content_type, attrs) when is_binary(content_type) do
    Logger.info(
      "Upserting #{content_type} with URL: #{attrs["url"]} and locale: #{attrs["locale"]}"
    )

    Source.upsert_from_file(content_type, attrs)
  end

  @doc """
  Extracts the locale from a file path.

  ## Parameters
    - file_path: String representing the path to the markdown file

  ## Returns
    - {:ok, locale} if the locale is successfully extracted
    - {:error, :invalid_file_path} if the locale cannot be extracted
  """
  @spec extract_locale(String.t()) ::
          {:ok, String.t()} | {:error, :invalid_file_path}
  def extract_locale(file_path) when is_binary(file_path) do
    Logger.debug("Extracting locale from file path: #{file_path}")

    case Regex.run(~r/\/(\w{2})\/[^\/]+\.md$/, file_path) do
      [_, locale] ->
        Logger.debug("Extracted locale: #{locale}")
        {:ok, locale}

      _ ->
        Logger.error("Failed to extract locale from file path: #{file_path}")
        {:error, :invalid_file_path}
    end
  end

  def extract_locale(file_path) do
    Logger.error("Invalid file path type: #{inspect(file_path)}")
    {:error, :invalid_file_path}
  end

  defp normalize_publication_status(status) when is_atom(status) do
    Atom.to_string(status)
  end

  defp normalize_publication_status(status) when is_binary(status), do: status
end
