defmodule Portfolio.Repo.Migrations.UpdateStoredAstType do
  use Ecto.Migration

  def change do
    execute(
      # Up
      """
      ALTER TABLE notes
      ALTER COLUMN stored_ast TYPE jsonb[] USING ARRAY[stored_ast]::jsonb[];
      """,
      # Down
      """
      ALTER TABLE notes
      ALTER COLUMN stored_ast TYPE jsonb USING stored_ast[1];
      """
    )

    execute(
      # Up
      """
      ALTER TABLE case_studies
      ALTER COLUMN stored_ast TYPE jsonb[] USING ARRAY[stored_ast]::jsonb[];
      """,
      # Down
      """
      ALTER TABLE case_studies
      ALTER COLUMN stored_ast TYPE jsonb USING stored_ast[1];
      """
    )
  end
end
