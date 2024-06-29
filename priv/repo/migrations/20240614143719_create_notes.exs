defmodule Portfolio.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :title, :string
      add :url, :string
      add :read_time, :integer
      add :introduction, :string
      add :file_path, :string
      add :locale, :string
      add :content, :text

      timestamps(type: :utc_datetime)
    end
    create unique_index(:notes, [:url], name: :unique_note_urls)
    create index(:notes, [:locale])
  end
end
