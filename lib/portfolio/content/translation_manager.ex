defmodule Portfolio.Content.TranslationManager do
  alias Portfolio.Repo
  alias Portfolio.Translation
  import Ecto.Query, only: [from: 2]

  def update_or_create_translation(case_study, locale, content) do
    translation = Repo.get_by(Translation, translatable_id: case_study.id, locale: locale)

    changeset =
      case translation do
        nil ->
          Translation.changeset(%Translation{}, %{
            translatable_id: case_study.id,
            locale: locale,
            content: content
          })
        _ ->
          Translation.changeset(translation, %{content: content})
      end

    Repo.insert_or_update(changeset)
  end

  def get_translations(content, content_type, locale) do
    translation_query =
      from t in Translation,
        where:
          t.translatable_id == ^content.id and
            t.translatable_type == ^Atom.to_string(content_type) and
            t.locale == ^locale

    Repo.all(translation_query)
    |> Enum.into(%{}, fn t -> {t.field_name, t.field_value} end)
  end
end
