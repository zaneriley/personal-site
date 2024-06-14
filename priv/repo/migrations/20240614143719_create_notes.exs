defmodule Portfolio.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :title, :string
      add :content, :text
      add :url, :string

      timestamps(type: :utc_datetime)
    end
  end
end
