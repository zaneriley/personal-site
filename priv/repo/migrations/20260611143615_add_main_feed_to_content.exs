defmodule Portfolio.Repo.Migrations.AddMainFeedToContent do
  @moduledoc false

  use Ecto.Migration

  # Nullable on purpose: null means "use the content type's default"
  # (case studies in the main feed, notes out — see _PROJECT_DOCS/feeds-spec.md),
  # so changing a type default later never needs a backfill.
  def change do
    alter table(:notes) do
      add :main_feed, :boolean, null: true
    end

    alter table(:case_studies) do
      add :main_feed, :boolean, null: true
    end
  end
end
