defmodule Portfolio.Content.TranslationManager do
  @moduledoc """
  A module for managing translations for case studies.

  This module provides functions for managing translations for case studies, including updating or creating translations, merging translations, and getting translations.

  ## Usage

  To use the TranslationManager module, you can call the `update_or_create_translation/4` function with the necessary arguments. This function will return a list of translations.

  For example, to update or create translations for a case study with the following metadata:

      %{
        title: "Case Study 1",
        url: "case-study-1",
        company: "TechCorp Solutions",
        role: "Senior Software Engineer",
        timeline: "January 2022 - June 2022",
        read_time: 5,
        platforms: ["Web", "Mobile", "Cloud"],
        introduction: "Introduction to Case Study 1",
        content: "Detailed content of Case Study 1",
        sort_order: 1
      }

  You can use the following code to update or create translations:

      translations = TranslationManager.update_or_create_translation(
        case_study,
        "en",
        %{
          title: "Case Study 1",
          url: "case-study-1",
          company: "TechCorp Solutions",
          role: "Senior Software Engineer",
          timeline: "January 2022 - June 2022",
          read_time: 5,
          platforms: ["Web", "Mobile", "Cloud"],
          introduction: "Introduction to Case Study 1",
          content: "Detailed content of Case Study 1",
          sort_order: 1
        },
        "Detailed content of Case Study 1"
      )

  The `translations` variable will contain the updated or created translations.

  ## Translations

  Translations are used to provide localized versions of case studies. Each translation is associated with a specific locale and field, and contains the translated content.

  """
  alias Portfolio.Repo
  alias Portfolio.CaseStudy
  alias Portfolio.Translation
  alias Portfolio.Content.TranslatableFields
  import Ecto.Query
  require Logger

  def update_or_create_translation(case_study, locale, metadata, content) do
    translatable_fields = [:title, :role, :company, :introduction, :timeline]

    (translatable_fields ++ [:content])
    |> Enum.map(
      &create_translation_attrs(case_study, locale, metadata, content, &1)
    )
    |> Enum.map(&upsert_translation/1)
  end

  # Creates a map of attributes for a translation
  # This function prepares the data for insertion or update in the database
  defp create_translation_attrs(case_study, locale, metadata, content, field) do
    %{
      translatable_id: case_study.id,
      translatable_type: CaseStudy.translatable_type_string(),
      locale: locale,
      field_name: Atom.to_string(field),
      field_value:
        if(field == :content, do: content, else: Map.get(metadata, field))
    }
  end

  # Upserts a translation (inserts if not exists, updates if exists)
  # This function checks if a translation exists and then calls the appropriate
  # insert or update function
  defp upsert_translation(attrs) do
    case Repo.get_by(Translation,
           translatable_id: attrs.translatable_id,
           translatable_type: attrs.translatable_type,
           locale: attrs.locale,
           field_name: attrs.field_name
         ) do
      nil -> insert_translation(attrs)
      existing -> update_translation(existing, attrs)
    end
  end

  defp insert_translation(attrs) do
    %Translation{}
    |> Translation.changeset(attrs)
    |> Repo.insert()
  end

  defp update_translation(existing, attrs) do
    existing
    |> Translation.changeset(attrs)
    |> Repo.update()
  end

  def merge_translations(content, locale) do
    default_data =
      Map.take(content, [
        :title,
        :role,
        :company,
        :introduction,
        :timeline,
        :content
      ])

    translations =
      content.translations
      |> Enum.filter(&(&1.locale == locale))
      |> Enum.into(%{}, fn t ->
        {String.to_atom(t.field_name), t.field_value}
      end)

    Map.merge(default_data, translations)
  end

  def get_translations(content, content_type, locale) do
    # Logger.debug(
    #   "Fetching translations for content_id: #{content.id}, content_type: #{content_type}, locale: #{locale}"
    # )

    translatable_type = CaseStudy.translatable_type_string()
    # Logger.debug("Using translatable_type: #{translatable_type}")

    translation_query =
      from t in Translation,
        where:
          t.translatable_id == ^content.id and
            t.translatable_type == ^translatable_type and
            t.locale == ^locale

    # Logger.debug("Translation query: #{inspect(translation_query)}")

    translations = Repo.all(translation_query)
    # Logger.debug("Fetched translations: #{inspect(translations)}")

    case translations do
      [] ->
        # Logger.warn(
        #   "TranslationManager.get_translations/3 No translations found for content_id: #{content.id}, content_type: #{content_type}, locale: #{locale}"
        # )

        %{}

      _ ->
        Enum.into(translations, %{}, fn t ->
          {safe_to_atom(t.field_name), t.field_value}
        end)
    end
  end

  # This approach ensures that we only create atoms for fields we expect,
  # avoiding potential atom table exhaustion.
  # It also maintains backwards compatibility by falling back to
  # string keys for any unexpected fields.
  defp safe_to_atom(field_name) do
    if field_name in Enum.map(TranslatableFields.all(), &Atom.to_string/1) do
      String.to_existing_atom(field_name)
    else
      field_name
    end
  end
end
