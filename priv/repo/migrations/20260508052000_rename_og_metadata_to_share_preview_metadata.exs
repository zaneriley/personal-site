defmodule Portfolio.Repo.Migrations.RenameOgMetadataToSharePreviewMetadata do
  @moduledoc false

  use Ecto.Migration

  def up do
    rename table(:notes), :og_title, to: :share_title
    rename table(:notes), :og_description, to: :share_description
    rename table(:notes), :og_image_hint, to: :share_image_direction
    rename table(:notes), :og_image_alt, to: :share_image_alt

    rename table(:case_studies), :og_title, to: :share_title
    rename table(:case_studies), :og_description, to: :share_description
    rename table(:case_studies), :og_image_hint, to: :share_image_direction
    rename table(:case_studies), :og_image_alt, to: :share_image_alt
  end

  def down do
    rename table(:notes), :share_title, to: :og_title
    rename table(:notes), :share_description, to: :og_description
    rename table(:notes), :share_image_direction, to: :og_image_hint
    rename table(:notes), :share_image_alt, to: :og_image_alt

    rename table(:case_studies), :share_title, to: :og_title
    rename table(:case_studies), :share_description, to: :og_description
    rename table(:case_studies), :share_image_direction, to: :og_image_hint
    rename table(:case_studies), :share_image_alt, to: :og_image_alt
  end
end
