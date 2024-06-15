defmodule Portfolio.Repo.Migrations.CreateCaseStudies do
  use Ecto.Migration

  def change do
    create table(:case_studies) do
      add :title, :string
      add :url, :string
      add :role, :string
      add :timeline, :string
      add :read_time, :integer
      add :platforms, {:array, :string}
      add :introduction, :string
      add :file_path, :string
      add :locale, :string
      add :content, :text
      add :company, :string
      add :sort_order, :integer
      timestamps(type: :utc_datetime)
    end

    create unique_index(:case_studies, [:url], name: :unique_case_study_urls)
  end
end
