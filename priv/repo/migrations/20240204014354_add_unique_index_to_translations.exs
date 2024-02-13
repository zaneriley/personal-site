defmodule Portfolio.Repo.Migrations.AddUniqueIndexToTranslations do
  use Ecto.Migration

  def change do
    create unique_index(:translations, [:translatable_id, :translatable_type, :locale, :field_name], name: :translations_unique_index)
  end
end
