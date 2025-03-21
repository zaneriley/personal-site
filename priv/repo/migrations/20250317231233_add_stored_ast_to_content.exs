defmodule Portfolio.Repo.Migrations.AddStoredAstToContent do
  use Ecto.Migration

  def change do
    # Add stored_ast to notes table
    alter table(:notes) do
      add :stored_ast, :jsonb
    end

    # Add stored_ast to case_studies table
    alter table(:case_studies) do
      add :stored_ast, :jsonb
    end
  end
end
