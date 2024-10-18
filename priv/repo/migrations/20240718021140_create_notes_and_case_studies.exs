defmodule Portfolio.Repo.Migrations.CreateNotesAndCaseStudies do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :text, null: false
      add :url, :string, null: false
      add :content, :text, null: false
      add :introduction, :text
      add :read_time, :integer
      add :word_count, :integer
      add :file_path, :string
      add :locale, :string, null: false
      add :published_at, :utc_datetime
      add :is_draft, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create table(:case_studies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :url, :string, null: false
      add :content, :text, null: false
      add :introduction, :text
      add :read_time, :integer
      add :word_count, :integer
      add :file_path, :string
      add :locale, :string, null: false
      add :published_at, :utc_datetime
      add :is_draft, :boolean, default: true
      add :company, :string
      add :role, :string
      add :timeline, :string
      add :platforms, {:array, :string}
      add :sort_order, :integer

      timestamps(type: :utc_datetime)
    end

    create table(:translations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :locale, :string, null: false
      add :field_name, :string, null: false
      add :field_value, :text, null: false
      add :translatable_id, :binary_id, null: false
      add :translatable_type, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:notes, [:url])
    create unique_index(:case_studies, [:url])
    create index(:translations, [:translatable_id, :translatable_type])

    create unique_index(
             :translations,
             [:translatable_id, :translatable_type, :locale, :field_name],
             name: :translations_unique_index
           )
  end
end
