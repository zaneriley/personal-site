defmodule Portfolio.Repo.Migrations.CreateContentPublicationVerdicts do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:content_publication_verdicts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content_sha, :string, null: false
      add :status, :string, null: false
      add :reason, :text
      add :promoted_paths, {:array, :string}, null: false, default: []
      add :removed_paths, {:array, :string}, null: false, default: []
      add :skipped_paths, {:array, :string}, null: false, default: []
      add :error_details, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:content_publication_verdicts, [:content_sha])
    create index(:content_publication_verdicts, [:status])
    create index(:content_publication_verdicts, [:inserted_at])
  end
end
