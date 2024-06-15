defmodule Portfolio.Repo.Migrations.UpdateTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :title, :string
      add :url, :string
      add :company, :string
      add :role, :string
      add :timeline, :string
      add :introduction, :string
      add :content, :text
      add :locale, :string, null: false
    end

    create unique_index(:translations, [:translatable_id, :translatable_type, :locale, :field_name], name: :translations_unique_index)
  end
end
