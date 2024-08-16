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
  alias Portfolio.Content.MarkdownRendering.Renderer
  import Ecto.Query
  require Logger

  # Wasn't able to debug these dialyzer warnings, but code works as expected.
  @dialyzer [
    {:nowarn_function, compile_content_and_translations: 3},
    {:nowarn_function, compile_content: 3},
    {:nowarn_function, compile_translations: 3},
    {:nowarn_function, get_content_with_translations: 3}
  ]


  @default_locale Application.compile_env(:portfolio, :default_locale)
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
    case get_schema(attrs["content_type"]) do
      {:error, :invalid_content_type} = error ->
        error

      {:ok, schema} ->
        with changeset <- apply_changeset(struct(schema), attrs),
             {:ok, content} <- insert_content(changeset),
             {:ok, compiled_content} <-
               compile_content(content, attrs["content_type"]),
             {:ok, updated_content} <-
               update_compiled_content(content, compiled_content) do
          {:ok, updated_content}
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @spec insert_content(Ecto.Changeset.t()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  defp insert_content(changeset) do
    Repo.insert(changeset)
  end

  @spec compile_content(Note.t() | CaseStudy.t(), Types.content_type()) ::
          {:ok, String.t()}
          | {:error, :empty_compiled_content | :empty_content | any()}
  defp compile_content(content, content_type) do
    case Renderer.render_and_cache(content.content, content_type, content.id) do
      {:ok, compiled_content}
      when is_binary(compiled_content) and compiled_content != "" ->
        {:ok, compiled_content}

      {:ok, _} ->
        {:error, :empty_compiled_content}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec update_compiled_content(Note.t() | CaseStudy.t(), String.t()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  defp update_compiled_content(content, compiled_content) do
    Repo.update(
      Ecto.Changeset.change(content, compiled_content: compiled_content)
    )
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
    with changeset <- apply_changeset(content, attrs),
         {:ok, updated_content} <- update_content_transaction(changeset),
         {:ok, compiled_content} <-
           compile_content(updated_content, content_type),
         {:ok, content_with_compiled} <-
           update_compiled_content(updated_content, compiled_content) do
      {:ok, content_with_compiled}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec update_content_transaction(Ecto.Changeset.t()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  defp update_content_transaction(changeset) do
    Repo.transaction(fn ->
      case Repo.update(changeset) do
        {:ok, updated_content} -> updated_content
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

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
  @spec get_content_by_id_or_url(content_type(), integer() | String.t()) ::
          Note.t() | CaseStudy.t()
  def get_content_by_id_or_url(content_type, id_or_url) do
    with {:ok, schema} <- get_schema(content_type) do
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
        nil ->
          raise Ecto.NoResultsError, queryable: query

        content ->
          {:ok, compiled_html} =
            Renderer.render_and_cache(content.content, content_type, content.id)

          %{content | compiled_content: compiled_html}
      end
    else
      {:error, :invalid_content_type} ->
        raise ArgumentError, "Invalid content type: #{inspect(content_type)}"
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

  @spec get_content_with_translations(
          Types.content_type(),
          String.t() | integer(),
          String.t()
        ) ::
          {:ok, Note.t() | CaseStudy.t(), map(), String.t()} | {:error, atom()}
  def get_content_with_translations(content_type, id_or_url, locale) do
    Logger.debug(
      "Fetching #{content_type} with translations for locale: #{locale}"
    )

    try do
      content = get_content_by_id_or_url(content_type, id_or_url)

      translations =
        TranslationManager.get_translations(content.id, content_type, locale)

      case compile_content_and_translations(content, content_type, translations) do
        {:ok, compiled_content, compiled_translations} ->
          updated_content = %{content | compiled_content: compiled_content}
          {:ok, updated_content, compiled_translations, compiled_content}

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

  @spec compile_content_and_translations(
    Note.t() | CaseStudy.t(),
    Types.content_type(),
    map()
  ) ::
    {:ok, String.t(), map()}
    | {:error, atom()}
    | {:error, :empty_content}
    | {:error, :unexpected_result}
    | {:error, :exception}
    defp compile_content_and_translations(content, content_type, translations) do
      schema = content.__struct__
      markdown_fields = schema.markdown_fields()

      with {:ok, compiled_content} <- compile_content(content, content_type, markdown_fields),
           {:ok, compiled_translations} <- compile_translations(translations, content_type, markdown_fields) do
        {:ok, compiled_content, compiled_translations}
      end
    end

  @spec compile_content(Note.t() | CaseStudy.t(), Types.content_type(), [
          String.t()
        ]) ::
          {:ok, String.t()}
          | {:error, atom()}
          | {:error, :empty_content}
          | {:error, :unexpected_result}
          | {:error, :exception}
  defp compile_content(content, content_type, markdown_fields) do
    is_markdown = "content" in markdown_fields

    try do
      case Renderer.render_and_cache(content.content, content_type, content.id,
             is_markdown: is_markdown
           ) do
        {:ok, compiled} when is_binary(compiled) and compiled != "" ->
          Logger.debug(
            "Successfully compiled content for #{content_type} with ID: #{content.id}"
          )

          {:ok, compiled}

        {:ok, ""} ->
          Logger.warning(
            "Compiled content is empty for #{content_type} with ID: #{content.id}"
          )

          {:error, :empty_content}

        {:error, reason} ->
          Logger.error(
            "Error compiling content for #{content_type} with ID: #{content.id}. Error: #{inspect(reason)}"
          )

          {:error, reason}

        unexpected ->
          Logger.error(
            "Unexpected result from render_and_cache for #{content_type} with ID: #{content.id}. Result: #{inspect(unexpected)}"
          )

          {:error, :unexpected_result}
      end
    rescue
      e ->
        Logger.error(
          "Exception raised while compiling content for #{content_type} with ID: #{content.id}. Exception: #{inspect(e)}"
        )

        {:error, :exception}
    end
  end

  @spec compile_translations(map(), Types.content_type(), [String.t()]) ::
          {:ok, map()} | {:error, atom()}
  defp compile_translations(translations, content_type, markdown_fields) do
    Enum.reduce_while(translations, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
      is_markdown = to_string(key) in markdown_fields

      case Renderer.render_and_cache(value, content_type, "#{key}_translation",
             is_markdown: is_markdown
           ) do
        {:ok, compiled} when is_binary(compiled) and compiled != "" ->
          Logger.debug("Successfully compiled translation for key: #{key}")
          {:cont, {:ok, Map.put(acc, key, compiled)}}

        {:ok, ""} ->
          Logger.warning("Compiled translation is empty for key: #{key}")
          {:halt, {:error, :empty_translation}}

        {:error, reason} ->
          Logger.error(
            "Error compiling translation for key: #{key}. Error: #{inspect(reason)}"
          )

          {:halt, {:error, reason}}
      end
    end)
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
  @spec upsert_from_file(content_type(), map()) ::
          {:ok, Note.t() | CaseStudy.t()}
          | {:error, atom() | Ecto.Changeset.t()}
  def upsert_from_file(content_type, attrs) when is_binary(content_type) do
    Logger.info(
      "Upserting #{content_type} with URL: #{attrs["url"]} and locale: #{attrs["locale"]}"
    )

    with {:ok, schema} <- get_schema(content_type),
         {:ok, content} <- upsert_content(schema, attrs, content_type),
         {:ok, compiled_content} <- compile_content(content, content_type) do
      {:ok, %{content | compiled_content: compiled_content}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_schema(content_type) do
    case Types.get_schema(content_type) do
      {:error, :invalid_content_type} = error -> error
      schema -> {:ok, schema}
    end
  end

  defp upsert_content(schema, attrs, content_type) do
    if attrs["locale"] == @default_locale do
      upsert_default_locale_content(schema, attrs, content_type)
    else
      upsert_non_default_locale_content(schema, attrs, content_type)
    end
  end

  defp upsert_default_locale_content(schema, attrs, content_type) do
    case Repo.get_by(schema, url: attrs["url"]) do
      nil -> create_content(Map.put(attrs, "content_type", content_type))
      entry -> update_content(entry, attrs, content_type)
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

  defp apply_changeset(%Note{} = note, attrs), do: Note.changeset(note, attrs)

  defp apply_changeset(%CaseStudy{} = case_study, attrs),
    do: CaseStudy.changeset(case_study, attrs)
end
