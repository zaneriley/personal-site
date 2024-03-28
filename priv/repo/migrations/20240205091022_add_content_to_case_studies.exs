defmodule Portfolio.Repo.Migrations.AddContentToCaseStudies do
  use Ecto.Migration

  def change do
    alter table(:case_studies) do
      add :content, :text
    end
  end
end
