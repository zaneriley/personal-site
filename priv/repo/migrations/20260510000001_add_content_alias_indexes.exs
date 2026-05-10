defmodule Portfolio.Repo.Migrations.AddContentAliasIndexes do
  @moduledoc false

  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create_if_not_exists index(:notes, [:aliases],
                           using: :gin,
                           name: :notes_aliases_index,
                           concurrently: true
                         )

    create_if_not_exists index(:case_studies, [:aliases],
                           using: :gin,
                           name: :case_studies_aliases_index,
                           concurrently: true
                         )
  end
end
