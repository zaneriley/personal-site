defmodule Portfolio.Repo.Migrations.AddOgMetadataToContent do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:notes) do
      add :og_title, :text
      add :og_description, :text
      add :og_image_hint, :text
      add :og_image_alt, :text
    end

    alter table(:case_studies) do
      add :og_title, :text
      add :og_description, :text
      add :og_image_hint, :text
      add :og_image_alt, :text
    end
  end
end
