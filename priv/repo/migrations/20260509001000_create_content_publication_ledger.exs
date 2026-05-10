defmodule Portfolio.Repo.Migrations.CreateContentPublicationLedger do
  @moduledoc false

  use Ecto.Migration

  def up do
    create table(:content_publication_generations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content_sha, :string, null: false
      add :source, :string, null: false, default: "publish"
      add :status, :string, null: false, default: "preparing"

      timestamps(type: :utc_datetime)
    end

    create index(:content_publication_generations, [:content_sha])
    create index(:content_publication_generations, [:status])

    create constraint(:content_publication_generations, :content_sha_format,
             check: "content_sha ~* '^[0-9a-f]{40}$'"
           )

    create constraint(:content_publication_generations, :content_generation_source,
             check: "source in ('publish', 'rollback', 'bootstrap')"
           )

    create constraint(:content_publication_generations, :content_generation_status,
             check: "status in ('preparing', 'live', 'superseded', 'failed')"
           )

    create table(:content_publication_ledger, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :github_delivery_id, :string, null: false
      add :content_sha, :string, null: false
      add :status, :string, null: false
      add :repository, :text
      add :ref, :string
      add :reason, :text

      add :content_publication_generation_id,
          references(:content_publication_generations,
            type: :binary_id,
            on_delete: :nilify_all
          )

      add :promoted_paths, {:array, :string}, null: false, default: []
      add :removed_paths, {:array, :string}, null: false, default: []
      add :skipped_paths, {:array, :string}, null: false, default: []
      add :structured_errors, :map, null: false, default: %{"errors" => []}
      add :received_at, :utc_datetime_usec
      add :started_at, :utc_datetime_usec
      add :finished_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:content_publication_ledger, [:github_delivery_id])
    create index(:content_publication_ledger, [:content_sha])
    create index(:content_publication_ledger, [:status])
    create index(:content_publication_ledger, [:inserted_at])

    create constraint(:content_publication_ledger, :content_sha_format,
             check: "content_sha ~* '^[0-9a-f]{40}$'"
           )

    create constraint(:content_publication_ledger, :content_publication_status,
             check: "status in ('accepted', 'rejected', 'ignored', 'duplicate', 'rollback')"
           )

    create table(:content_publication_states, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: "default"
      add :live_content_sha, :string
      add :last_good_content_sha, :string
      add :last_accepted_content_sha, :string
      add :last_rejected_content_sha, :string
      add :last_rejected_reason, :text
      add :last_ignored_content_sha, :string
      add :last_ignored_reason, :text
      add :last_delivery_id, :string
      add :current_sync_state, :string, null: false, default: "idle"
      add :last_failure_reason, :text

      add :live_content_publication_generation_id,
          references(:content_publication_generations,
            type: :binary_id,
            on_delete: :nilify_all
          )

      add :last_good_content_publication_generation_id,
          references(:content_publication_generations,
            type: :binary_id,
            on_delete: :nilify_all
          )

      timestamps(type: :utc_datetime)
    end

    create unique_index(:content_publication_states, [:name])

    create constraint(:content_publication_states, :singleton_state_name,
             check: "name = 'default'"
           )

    create constraint(:content_publication_states, :content_sync_state,
             check: "current_sync_state in ('idle', 'running', 'failed')"
           )

    create constraint(:content_publication_states, :live_content_sha_format,
             check: "live_content_sha is null or live_content_sha ~* '^[0-9a-f]{40}$'"
           )

    create constraint(:content_publication_states, :last_good_content_sha_format,
             check: "last_good_content_sha is null or last_good_content_sha ~* '^[0-9a-f]{40}$'"
           )

    create constraint(:content_publication_states, :last_accepted_content_sha_format,
             check:
               "last_accepted_content_sha is null or last_accepted_content_sha ~* '^[0-9a-f]{40}$'"
           )

    create constraint(:content_publication_states, :last_rejected_content_sha_format,
             check:
               "last_rejected_content_sha is null or last_rejected_content_sha ~* '^[0-9a-f]{40}$'"
           )

    create constraint(:content_publication_states, :last_ignored_content_sha_format,
             check:
               "last_ignored_content_sha is null or last_ignored_content_sha ~* '^[0-9a-f]{40}$'"
           )

    alter table(:notes) do
      add :publication_generation_id,
          references(:content_publication_generations,
            type: :binary_id,
            on_delete: :nilify_all
          )
    end

    alter table(:case_studies) do
      add :publication_generation_id,
          references(:content_publication_generations,
            type: :binary_id,
            on_delete: :nilify_all
          )
    end

    drop_if_exists unique_index(:notes, [:url], name: :notes_url_index)
    drop_if_exists unique_index(:case_studies, [:url], name: :case_studies_url_index)

    create unique_index(:notes, [:url],
             where: "publication_generation_id IS NULL",
             name: :notes_url_unpublished_index
           )

    create unique_index(:notes, [:url, :publication_generation_id],
             where: "publication_generation_id IS NOT NULL",
             name: :notes_url_publication_generation_index
           )

    create unique_index(:case_studies, [:url],
             where: "publication_generation_id IS NULL",
             name: :case_studies_url_unpublished_index
           )

    create unique_index(:case_studies, [:url, :publication_generation_id],
             where: "publication_generation_id IS NOT NULL",
             name: :case_studies_url_publication_generation_index
           )
  end

  def down do
    drop_if_exists unique_index(:case_studies, [:url, :publication_generation_id],
                     name: :case_studies_url_publication_generation_index
                   )

    drop_if_exists unique_index(:case_studies, [:url], name: :case_studies_url_unpublished_index)

    drop_if_exists unique_index(:notes, [:url, :publication_generation_id],
                     name: :notes_url_publication_generation_index
                   )

    drop_if_exists unique_index(:notes, [:url], name: :notes_url_unpublished_index)

    collapse_generated_content_for_rollback()

    create unique_index(:case_studies, [:url], name: :case_studies_url_index)
    create unique_index(:notes, [:url], name: :notes_url_index)

    alter table(:case_studies) do
      remove :publication_generation_id
    end

    alter table(:notes) do
      remove :publication_generation_id
    end

    drop table(:content_publication_states)
    drop table(:content_publication_ledger)
    drop table(:content_publication_generations)
  end

  defp collapse_generated_content_for_rollback do
    collapse_generated_content_for_rollback(:notes, "note")
    collapse_generated_content_for_rollback(:case_studies, "case_study")
  end

  defp collapse_generated_content_for_rollback(table_name, translatable_type) do
    table = Atom.to_string(table_name)

    execute("""
    WITH live_state AS (
      SELECT live_content_publication_generation_id AS live_generation_id
      FROM content_publication_states
      WHERE name = 'default'
      LIMIT 1
    ),
    deleted_content AS (
      DELETE FROM #{table}
      WHERE publication_generation_id IS NOT NULL
        AND publication_generation_id IS DISTINCT FROM (
          SELECT live_generation_id FROM live_state
        )
      RETURNING id
    )
    DELETE FROM translations
    USING deleted_content
    WHERE translations.translatable_id = deleted_content.id
      AND translations.translatable_type = '#{translatable_type}'
    """)

    execute("""
    WITH live_urls AS (
      SELECT url
      FROM #{table}
      WHERE publication_generation_id = (
        SELECT live_content_publication_generation_id
        FROM content_publication_states
        WHERE name = 'default'
        LIMIT 1
      )
    ),
    deleted_content AS (
      DELETE FROM #{table}
      WHERE publication_generation_id IS NULL
        AND url IN (SELECT url FROM live_urls)
      RETURNING id
    )
    DELETE FROM translations
    USING deleted_content
    WHERE translations.translatable_id = deleted_content.id
      AND translations.translatable_type = '#{translatable_type}'
    """)
  end
end
