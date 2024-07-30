defmodule Portfolio.Content.EntryManager do
  @moduledoc """
  Manages the lifecycle of content entries in the Portfolio application.

  This module handles creating, updating, deleting, and retrieving content entries
  such as Notes and Case Studies. It serves as an intermediary between the database
  and application logic, coordinating with TranslationManager for non-default locales.
  """
  alias Portfolio.Repo
  alias Portfolio.Content.Types
  alias Portfolio.Content.Schemas.{Note, CaseStudy}
  alias Portfolio.Content.TranslationManager
  import Ecto.Query
  require Logger

  @default_locale Application.compile_env(:portfolio, :default_locale)

  @doc """
  Creates a new content item based on the provided attributes.

  This function determines the appropriate schema (Note or CaseStudy) based on the
  "content_type" attribute, and then creates a new record in the database.

  ## Parameters

    - attrs: A map containing the attributes for the new content item. Must include
      a "content_type" key with a value of either "note" or "case_study".

  ## Returns

    - `{:ok, content}` if the content was successfully created, where `content` is
      either a `Note.t()` or `CaseStudy.t()`.
    - `{:error, changeset}` if there was a validation error.
    - `{:error, :invalid_content_type}` if an invalid content type was provided.
    - `{:error, reason}` for other errors.

  ## Examples

      iex> create_content(%{"content_type" => "note", "title" => "My Note", "content" => "Some content"})
      {:ok, %Portfolio.Content.Schemas.Note{...}}

      iex> create_content(%{"content_type" => "case_study", "title" => "Case Study", "company" => "ACME"})
      {:ok, %Portfolio.Content.Schemas.CaseStudy{...}}

      iex> create_content(%{"content_type" => "invalid"})
      {:error, :invalid_content_type}
  """
  @spec create_content(map()) ::
          {:ok,
           Portfolio.Content.Schemas.Note.t()
           | Portfolio.Content.Schemas.CaseStudy.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, :invalid_content_type}
          | {:error, any()}
  def create_content(attrs) do
    Logger.debug("Creating content with attrs: #{inspect(attrs)}")

    case Types.get_schema(attrs["content_type"]) do
      {:error, :invalid_content_type} ->
        {:error, :invalid_content_type}

      schema ->
        Logger.debug("Schema found: #{inspect(schema)}")

        struct(schema)
        |> apply_changeset(attrs)
        |> Repo.insert()
    end
  end

  def update_content(content, attrs) do
    content
    |> apply_changeset(attrs)
    |> Repo.update()
  end

  def delete_content(content) do
    Repo.delete(content)
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
  @spec get_content_by_id_or_url(String.t(), integer() | String.t()) ::
          Note.t() | CaseStudy.t()
  def get_content_by_id_or_url(content_type, id_or_url) do
    schema = Types.get_schema(content_type)

    query =
      cond do
        uuid?(id_or_url) ->
          from e in schema, where: e.id == ^id_or_url

        is_binary(id_or_url) ->
          from e in schema, where: e.url == ^id_or_url

        true ->
          raise ArgumentError,
                "Invalid id_or_url provided: #{inspect(id_or_url)}"
      end

    case Repo.one(query) do
      nil -> raise Ecto.NoResultsError, queryable: query
      content -> content
    end
  end

  defp uuid?(string) do
    case UUID.info(string) do
      {:ok, _} -> true
      {:error, _} -> false
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
    content_schema = Types.get_schema(type)
    query = from(c in content_schema, where: c.id in ^translatable_ids)

    case Repo.all(query) do
      [] -> raise Ecto.NoResultsError, queryable: query
      content -> {:ok, content}
    end
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
    schema = Types.get_schema(content_type)
    query = sort(schema, opts[:sort_by], opts[:sort_order])
    contents = Repo.all(query)

    content_ids = Enum.map(contents, & &1.id)

    translations =
      TranslationManager.batch_get_translations(
        content_ids,
        content_type,
        locale
      )

    Logger.debug("Fetched translations: #{inspect(translations)}")

    result =
      Enum.map(contents, fn content ->
        content_translations = Map.get(translations, content.id, %{})
        Logger.debug("Content before merge: #{inspect(content)}")

        Logger.debug(
          "Translations for content: #{inspect(content_translations)}"
        )

        merged_content = Map.put(content, :translations, content_translations)
        Logger.debug("Content after merge: #{inspect(merged_content)}")
        merged_content
      end)

    result
  end

  defp sort(query, nil, _), do: query

  defp sort(query, sort_by, sort_order) do
    order_by(query, {^sort_order, ^sort_by})
  end

  ##########################################
  # Handle Translations                    #
  ##########################################

  @doc """
  Fetches content with its translations.

  ## Parameters
  - `content_type`: The type of content to retrieve ("note" or "case_study").
  - `identifier`: The unique identifier (URL or ID) of the content.
  - `locale`: The locale of the translations to fetch.

  ## Returns
  - `{:ok, content, translations}`: Content and its translations if found.
  - `{:error, :not_found}`: If no content is found.
  """
  @spec get_content_with_translations(
          String.t(),
          integer() | String.t(),
          String.t()
        ) ::
          {:ok, Note.t() | CaseStudy.t(), map()} | no_return()
  def get_content_with_translations(content_type, identifier, locale) do
    content = get_content_by_id_or_url(content_type, identifier)

    translations =
      TranslationManager.get_translations(content.id, content_type, locale)

    {:ok, content, translations}
  end

  ##########################################
  # Updates from the markdown file changes #
  ##########################################

  def upsert_from_file(content_type, attrs) when is_atom(content_type) do
    upsert_from_file(Atom.to_string(content_type), attrs)
  end

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
  @spec upsert_from_file(String.t(), map()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, any()}
  def upsert_from_file(content_type, attrs) do
    Logger.debug(
      "upsert_from_file called with content_type: #{inspect(content_type)}, attrs: #{inspect(attrs)}"
    )

    stringified_attrs = stringify_keys(attrs)
    schema = Types.get_schema(content_type)
    Logger.debug("Schema returned from get_schema: #{inspect(schema)}")

    url = stringified_attrs["url"]
    locale = stringified_attrs["locale"]

    Logger.info(
      "Attempting to upsert #{content_type} with URL: #{url} and locale: #{locale}"
    )

    result =
      if locale == @default_locale do
        upsert_default_locale_content(schema, stringified_attrs, content_type)
      else
        upsert_non_default_locale_content(
          schema,
          stringified_attrs,
          content_type
        )
      end

    case result do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, reason}
    end
  end

  defp upsert_default_locale_content(schema, attrs, content_type) do
    case Repo.get_by(schema, url: attrs["url"]) do
      nil -> create_content(Map.put(attrs, "content_type", content_type))
      entry -> update_content(entry, attrs)
    end
  end

  defp upsert_non_default_locale_content(schema, attrs, content_type) do
    case Repo.get_by(schema, url: attrs["url"]) do
      nil -> create_entry_with_translations(attrs, content_type)
      entry -> update_entry_translations(entry, attrs)
    end
  end

  defp create_entry_with_translations(attrs, content_type) do
    with {:ok, entry} <-
           create_content(Map.put(attrs, "content_type", content_type)),
         {:ok, _translations} <- create_or_update_translations(entry, attrs) do
      {:ok, entry}
    end
  end

  defp update_entry_translations(entry, attrs) do
    case create_or_update_translations(entry, attrs) do
      {:ok, _translations} -> {:ok, entry}
      error -> error
    end
  end

  defp create_or_update_translations(entry, attrs) do
    case TranslationManager.create_or_update_translations(
           entry,
           attrs["locale"],
           attrs
         ) do
      {:ok, _translations} -> {:ok, entry}
      {:error, reason} -> {:error, reason}
    end
  end

  defp log_result({:ok, _content} = result),
    do: Logger.info("Content upserted successfully")

  defp log_result({:error, changeset}),
    do: Logger.error("Failed to upsert content: #{inspect(changeset.errors)}")

  # Helper function to convert all keys to strings
  @spec stringify_keys(map()) :: map()
  defp stringify_keys(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp apply_changeset(%Note{} = note, attrs), do: Note.changeset(note, attrs)

  defp apply_changeset(%CaseStudy{} = case_study, attrs),
    do: CaseStudy.changeset(case_study, attrs)
end
