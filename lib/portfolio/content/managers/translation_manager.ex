defmodule Portfolio.Content.TranslationManager do
  @moduledoc """
  Manages translations for content items in the Portfolio application.

  This module provides functionality to create, update, and retrieve translations
  for various content types such as Notes and Case Studies. It interacts with the
  Translation schema and handles the logic for managing multilingual content.

  Key features:
  - Create or update translations for content items
  - Fetch translations for specific content and locale
  - Merge original content with translated fields

  The module uses Ecto for database operations and includes logging for debugging
  and error tracking.
  """
  alias Portfolio.Repo
  alias Portfolio.Content.TranslatableFields
  alias Portfolio.Content.Schemas.{Translation, Note, CaseStudy}
  import Ecto.Query
  require Logger

  @type content :: Note.t() | CaseStudy.t()
  @type translation_result :: {:ok, [Translation.t()]} | {:error, any()}

  @supported_locales Application.compile_env(:portfolio, :supported_locales)

  @doc """
  Creates or updates translations for a content item.

  ## Parameters
    - content: The content item (Note or CaseStudy)
    - locale: String representing the locale of the translations
    - attrs: Map of attributes containing the translated values

  ## Returns
    - {:ok, list of translations} if successful
    - {:error, reason} if there was an error

  Note: Nil values in attrs are ignored. Empty strings clear existing translations.
  """
  @spec create_or_update_translations(struct(), String.t(), map()) ::
          {:ok, [Translation.t()]} | {:error, any()}
  def create_or_update_translations(content, locale, attrs) do
    validate_locale(locale)

    translatable_fields =
      TranslatableFields.translatable_fields(content.__struct__)

    results =
      Enum.map(
        translatable_fields,
        &process_translatable_field(&1, content, locale, attrs)
      )

    aggregate_translation_results(results)
  end

  @doc """
  Fetches translations for a specific content item and locale.

  ## Parameters
  - `content_id`: The ID of the content item.
  - `content_type`: The type of the content ("note" or "case_study").
  - `locale`: The locale of the translations to fetch.

  ## Returns
  - `%{String.t() => String.t()}`: A map of field names to translated values.
  """
  @spec get_translations(binary(), String.t(), String.t()) :: %{
          String.t() => String.t()
        }
  def get_translations(content_id, content_type, locale) do
    Logger.debug(
      "Fetching translations for content_id: #{content_id}, content_type: #{content_type}, locale: #{locale}"
    )

    translations =
      from(t in Translation,
        where:
          t.translatable_id == ^content_id and
            t.translatable_type == ^content_type and
            t.locale == ^locale,
        select: {t.field_name, t.field_value}
      )
      |> Repo.all()
      |> Enum.into(%{})

    Logger.debug("Fetched translations: #{inspect(translations)}")
    translations
  end

  @doc """
  Preloads translations for a list of content items.

  ## Parameters
    - query: The initial query for content items
    - locale: The locale to preload translations for

  ## Returns
    - A query with preloaded translations
  """
  @spec preload_translations(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  def preload_translations(query, locale) do
    from q in query,
      preload: [
        translations: ^from(t in Translation, where: t.locale == ^locale)
      ]
  end

  @doc """
  Batch retrieves translations for multiple content items.

  ## Parameters
    - content_ids: List of content IDs
    - content_type: The type of the content ("note" or "case_study")
    - locale: The locale of the translations to fetch

  ## Returns
    - A map where keys are content IDs and values are maps of translations
  """
  @spec batch_get_translations([binary()], String.t(), String.t()) :: %{
          binary() => %{String.t() => String.t()}
        }
  def batch_get_translations(content_ids, content_type, locale) do
    Logger.debug(
      "Batch fetching translations for content_type: #{content_type}, locale: #{locale}"
    )

    from(t in Translation,
      where:
        t.translatable_id in ^content_ids and
          t.translatable_type == ^content_type and
          t.locale == ^locale,
      select: {t.translatable_id, {t.field_name, t.field_value}}
    )
    |> Repo.all()
    |> Enum.group_by(&elem(&1, 0), fn {_, translation} -> translation end)
    |> Map.new(fn {id, translations} -> {id, Enum.into(translations, %{})} end)
  end

  # Private functions
  defp validate_locale(locale) do
    unless locale in @supported_locales do
      Logger.warning(
        "Creating/updating translations for unsupported locale: #{locale}"
      )
    end
  end

  defp process_translatable_field(field, content, locale, attrs) do
    field_name = Atom.to_string(field)
    field_value = Map.get(attrs, field_name)

    if is_nil(field_value) do
      nil
    else
      normalized_value = normalize_field_value(field_value)
      upsert_translation(content, locale, field_name, normalized_value)
    end
  end

  defp normalize_field_value(value) when is_integer(value),
    do: Integer.to_string(value)

  defp normalize_field_value(value), do: value

  defp aggregate_translation_results(results) do
    if Enum.any?(results, &match?({:error, _}, &1)) do
      {:error, "Failed to create or update some translations"}
    else
      {:ok, Enum.reject(results, &is_nil/1)}
    end
  end

  defp upsert_translation(content, locale, field_name, field_value) do
    attrs = %{
      translatable_id: content.id,
      translatable_type: content.__struct__.translatable_type(),
      locale: locale,
      field_name: field_name,
      field_value: field_value
    }

    existing_translation =
      Repo.get_by(
        Translation,
        Map.take(attrs, [
          :translatable_id,
          :translatable_type,
          :locale,
          :field_name
        ])
      )

    (existing_translation || %Translation{})
    |> Translation.changeset(attrs)
    |> Repo.insert_or_update()
    |> case do
      {:ok, translation} ->
        translation

      {:error, changeset} ->
        Logger.error(
          "Failed to upsert translation: #{inspect(changeset.errors)}"
        )

        nil
    end
  end

  # defp create_translation(attrs) do
  #   %Translation{}
  #   |> Translation.changeset(attrs)
  #   |> Repo.insert()
  #   |> case do
  #     {:ok, translation} ->
  #       {:ok, translation}

  #     {:error, changeset} ->
  #       {:error, "Failed to create translation: #{inspect(changeset.errors)}"}
  #   end
  # end

  # defp update_translation(translation, attrs) do
  #   translation
  #   |> Translation.changeset(attrs)
  #   |> Repo.update()
  #   |> case do
  #     {:ok, translation} ->
  #       {:ok, translation}

  #     {:error, changeset} ->
  #       {:error, "Failed to update translation: #{inspect(changeset.errors)}"}
  #   end
  # end
end
