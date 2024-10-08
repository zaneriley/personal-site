defmodule Portfolio.Content do
  @moduledoc """
  The Content context.

  Provides a unified interface for managing content-related operations,
  delegating to specialized modules like EntryManager and TranslationManager.
  """
  alias Portfolio.Content.Types
  alias Portfolio.Content.EntryManager
  alias Portfolio.Content.Schemas.{Note, CaseStudy}
  require Logger

  defmodule InvalidContentTypeError do
    defexception [:message]
  end

  @type content_type :: Types.content_type()
  @type content_id :: integer()
  @type content_url :: String.t()
  @type content_identifier :: content_id() | content_url()

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
    EntryManager.list_contents(type, opts, locale)
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
    - ContentTypeMismatchError: If the found content type doesn't match the requested type
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
    EntryManager.get_content_by_id_or_url(type, id_or_url)
  end

  @spec create(content_type(), map()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  def create(type, attrs) do
    Logger.debug(
      "Create called with type: #{inspect(type)}, attrs: #{inspect(attrs)}"
    )

    attrs = Map.put(attrs, "content_type", type)
    Logger.debug("Modified attrs: #{inspect(attrs)}")

    try do
      EntryManager.create_content(attrs)
    rescue
      Portfolio.Content.InvalidContentTypeError ->
        {:error, :invalid_content_type}
    end
  end

  @spec update(content_type(), Note.t() | CaseStudy.t(), map()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  def update(type, content, attrs) do
    EntryManager.update_content(content, attrs, type)
  end

  @spec delete(content_type(), Note.t() | CaseStudy.t()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  def delete(_type, content) do
    EntryManager.delete_content(content)
  end

  @spec change(content_type(), Note.t() | CaseStudy.t() | map(), map()) ::
          Ecto.Changeset.t() | {:error, :invalid_content_type}
  def change(type, content, attrs \\ %{}) do
    Logger.debug("Content.change called with:")
    Logger.debug("  type: #{inspect(type)}")
    Logger.debug("  content: #{inspect(content)}")
    Logger.debug("  attrs: #{inspect(attrs)}")

    case Types.get_schema(type) do
      {:error, :invalid_content_type} ->
        Logger.error("Invalid content type: #{inspect(type)}")
        {:error, :invalid_content_type}

      schema when is_atom(schema) ->
        Logger.debug("Using schema: #{inspect(schema)}")
        changeset = schema.changeset(content, attrs)
        Logger.debug("Resulting changeset: #{inspect(changeset)}")
        changeset
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
          String.t() | integer(),
          String.t()
        ) ::
          {:ok, Note.t() | CaseStudy.t(), map(), String.t()} | {:error, atom()}
  def get_with_translations(content_type, identifier, locale) do
    EntryManager.get_content_with_translations(content_type, identifier, locale)
  end

  @doc """
  Upserts content from a file based on the content type and attributes provided.

  This function delegates the actual upsert operation to EntryManager after
  performing some basic logging. It handles both atom and string content types.

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

    EntryManager.upsert_from_file(content_type, attrs)
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
end
