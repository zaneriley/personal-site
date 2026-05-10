defmodule Portfolio.Repo.Migrations.AddAliasesToContent do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:notes) do
      add :aliases, {:array, :string}, null: false, default: []
    end

    alter table(:case_studies) do
      add :aliases, {:array, :string}, null: false, default: []
    end
  end
end
