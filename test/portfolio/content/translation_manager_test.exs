defmodule Portfolio.Content.TranslationManagerTest do
  use ExUnit.Case, async: true
  use Portfolio.DataCase
  alias Portfolio.Content.TranslationManager
  import Portfolio.AdminFixtures

  describe "update_or_create_translation/3" do
    setup do
      case_study = case_study_fixture()
      %{case_study: case_study}
    end

    test "creates a new translation when it doesn't exist", %{case_study: case_study} do
      locale = "ja"
      content = "Japanese content"
      assert {:ok, translation} = TranslationManager.update_or_create_translation(case_study, locale, content)
      assert translation.locale == locale
      assert translation.content == content
    end

    test "updates existing translation when it exists", %{case_study: case_study} do
      locale = "ja"
      content = "Japanese content"
      {:ok, translation} = TranslationManager.update_or_create_translation(case_study, locale, content)

      new_content = "Updated Japanese content"
      assert {:ok, updated_translation} = TranslationManager.update_or_create_translation(case_study, locale, new_content)
      assert updated_translation.id == translation.id
      assert updated_translation.content == new_content
    end
  end
end
