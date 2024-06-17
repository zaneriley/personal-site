defmodule Portfolio.Repo.Migrations.CreateTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :locale, :string
      add :field_name, :string
      add :field_value, :text
      add :translatable_id, :integer
      add :translatable_type, :string
      add :title, :string
      add :url, :string
      add :company, :string
      add :role, :string
      add :timeline, :string
      add :introduction, :string
      add :content, :text

      timestamps()
    end

    create index(:translations, [:translatable_id])
    create index(:translations, [:translatable_type])
    create index(:translations, [:locale])

    create unique_index(
             :translations,
             [:translatable_id, :translatable_type, :locale, :field_name],
             name: :translations_unique_index
           )
  end
end
