defmodule Portfolio.Repo.Migrations.RenameIndexToSortOrder do
  use Ecto.Migration

  def change do
    rename table(:case_studies), :index, to: :sort_order
  end
end
