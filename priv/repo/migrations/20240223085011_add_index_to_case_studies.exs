defmodule Portfolio.Repo.Migrations.AddIndexToCaseStudies do
  use Ecto.Migration

  def change do
    alter table(:case_studies) do
      add :index, :integer
    end
  end
end
