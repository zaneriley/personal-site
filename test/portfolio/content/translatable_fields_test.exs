defmodule Portfolio.Content.TranslatableFieldsTest do
  use ExUnit.Case, async: true

  alias Portfolio.Content.Schemas.Project
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Content.TranslatableFields

  describe "translatable_fields/1" do
    test "uses explicit note translation policy" do
      assert TranslatableFields.translatable_fields(Note) == [
               :title,
               :url,
               :content,
               :introduction,
               :share_title,
               :share_description,
               :share_image_direction,
               :share_image_alt
             ]
    end

    test "uses explicit project translation policy" do
      assert TranslatableFields.translatable_fields(Project) == [
               :title,
               :content,
               :introduction,
               :share_title,
               :share_description,
               :share_image_direction,
               :share_image_alt,
               :company,
               :role,
               :timeline
             ]
    end
  end

  describe "translatable_field?/2" do
    test "respects the explicit schema policy" do
      assert TranslatableFields.translatable_field?(
               Note,
               :share_image_direction
             )

      refute TranslatableFields.translatable_field?(Project, :url)
      refute TranslatableFields.translatable_field?(Project, :platforms)
    end
  end
end
