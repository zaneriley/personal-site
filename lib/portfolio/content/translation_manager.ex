defmodule Portfolio.Content.TranslationManager do
  alias Portfolio.Repo
  alias Portfolio.CaseStudy

  alias Portfolio.Translation
  import Ecto.Query
  require Logger

  def update_or_create_translation(case_study, locale, metadata, content) do
    translatable_fields = [:title, :role, :company, :introduction, :timeline]

    translations =
      Enum.map(translatable_fields, fn field ->
        attrs = %{
          translatable_id: case_study.id,
          translatable_type: CaseStudy.translatable_type_string(),
          locale: locale,
          field_name: Atom.to_string(field),
          field_value: Map.get(metadata, field)
        }

        case Repo.get_by(Translation,
               translatable_id: case_study.id,
               translatable_type: CaseStudy.translatable_type_string(),
               locale: locale,
               field_name: Atom.to_string(field)
             ) do
          nil -> %Translation{} |> Translation.changeset(attrs) |> Repo.insert()
          existing -> existing |> Translation.changeset(attrs) |> Repo.update()
        end
      end)

    # Add content translation
    content_attrs = %{
      translatable_id: case_study.id,
      translatable_type: CaseStudy.translatable_type_string(),
      locale: locale,
      field_name: "content",
      field_value: content
    }

    content_translation =
      case Repo.get_by(Translation,
             translatable_id: case_study.id,
             translatable_type: "CaseStudy",
             locale: locale,
             field_name: "content"
           ) do
        nil ->
          %Translation{}
          |> Translation.changeset(content_attrs)
          |> Repo.insert()

        existing ->
          existing |> Translation.changeset(content_attrs) |> Repo.update()
      end

    translations ++ [content_translation]
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
          {String.to_atom(t.field_name), t.field_value}
        end)
    end
  end
end
