defmodule Portfolio.Repo.Migrations.CreateTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :locale, :string
      add :field_name, :string
      add :field_value, :text
      add :translatable_id, :integer
      add :translatable_type, :string

      timestamps()
    end

    create index(:translations, [:translatable_id])
    create index(:translations, [:translatable_type])
    create index(:translations, [:locale])
  end
end
