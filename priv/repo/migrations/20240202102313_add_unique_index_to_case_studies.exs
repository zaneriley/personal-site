defmodule Portfolio.Repo.Migrations.AddUniqueIndexToCaseStudies do
  use Ecto.Migration

  def change do
    create unique_index(:case_studies, [:url], name: :unique_case_study_urls)
  end
end
