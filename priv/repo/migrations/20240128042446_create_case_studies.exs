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

      timestamps()
    end
  end
end
