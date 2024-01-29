defmodule Portfolio.Repo.Migrations.AddUrlToCaseStudies do
  use Ecto.Migration

  def change do
    alter table(:case_studies) do
      add :url, :string
    end
  end
end
