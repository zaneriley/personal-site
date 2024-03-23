defmodule Portfolio.Repo.Migrations.AddFilePathToCaseStudies do
  use Ecto.Migration

  def change do
    alter table(:case_studies) do
      add :file_path, :string
      add :locale, :string
    end
  end
end
