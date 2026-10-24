defmodule Portfolio.Repo.Migrations.RenameCaseStudiesToProjects do
  @moduledoc false

  # The site calls its collection "Work" and each item a "project". Postgres
  # keeps index and constraint names on a table rename, so rename those too:
  # the schema derives its unique-constraint names from the table name.
  use Ecto.Migration

  @indexes ~w(aliases_index pkey url_publication_generation_index url_unpublished_index)

  def up do
    rename table(:case_studies), to: table(:projects)

    for suffix <- @indexes do
      execute "ALTER INDEX case_studies_#{suffix} RENAME TO projects_#{suffix}"
    end

    execute """
    ALTER TABLE projects RENAME CONSTRAINT
      case_studies_publication_generation_id_fkey TO projects_publication_generation_id_fkey
    """

    execute "UPDATE translations SET translatable_type = 'project' WHERE translatable_type = 'case_study'"
  end

  def down do
    execute "UPDATE translations SET translatable_type = 'case_study' WHERE translatable_type = 'project'"

    execute """
    ALTER TABLE projects RENAME CONSTRAINT
      projects_publication_generation_id_fkey TO case_studies_publication_generation_id_fkey
    """

    for suffix <- @indexes do
      execute "ALTER INDEX projects_#{suffix} RENAME TO case_studies_#{suffix}"
    end

    rename table(:projects), to: table(:case_studies)
  end
end
