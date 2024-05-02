defmodule Portfolio.Repo.Migrations.AddCompanyToCaseStudies do
  use Ecto.Migration

  def change do
    alter table(:case_studies) do
      add :company, :string
    end
  end
end
