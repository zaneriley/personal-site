defmodule Portfolio.Content.TranslationManagerTest do
  use ExUnit.Case, async: true
  use Portfolio.DataCase
  alias Portfolio.Content.TranslationManager
  alias Portfolio.Repo
  import Portfolio.AdminFixtures

  describe "update_or_create_translation/4" do
    setup do
      case_study =
        case_study_fixture(%{include_translations: true})
        |> Repo.preload(:translations)

      %{case_study: case_study}
    end

    test "creates a new translation when it doesn't exist", %{
      case_study: case_study
    } do
      # Using French as it doesn't exist in the fixture
      locale = "fr"

      new_metadata = %{
        title: "Titre en français",
        role: "Ingénieur logiciel senior",
        company: "Solutions TechCorp",
        introduction:
          "Révolutionner la gestion des stocks pour une plateforme e-commerce mondiale.",
        timeline: "Janvier 2022 - Juin 2022"
      }

      new_content = "Contenu en français..."

      updated_translations =
        TranslationManager.update_or_create_translation(
          case_study,
          locale,
          new_metadata,
          new_content
        )

      # 5 metadata fields + 1 content field
      assert length(updated_translations) == 6

      Enum.each(updated_translations, fn {:ok, translation} ->
        assert translation.locale == locale
        assert translation.translatable_id == case_study.id
        assert translation.translatable_type == "case_study"
        field_name = translation.field_name

        expected_value =
          if field_name == "content",
            do: new_content,
            else: new_metadata[String.to_atom(field_name)]

        assert translation.field_value == expected_value
      end)
    end

    test "updates existing translation when it exists", %{
      case_study: case_study
    } do
      # First, let's check if Japanese translations exist
      existing_translations =
        Enum.filter(case_study.translations, &(&1.locale == "ja"))

      locale = "ja"

      new_metadata = %{
        title: "更新された日本語タイトル",
        role: "更新された役割",
        company: "更新された会社名",
        introduction: "更新された紹介文",
        timeline: "2022年7月 - 2022年12月"
      }

      new_content = "更新された日本語コンテンツ"

      updated_translations =
        TranslationManager.update_or_create_translation(
          case_study,
          locale,
          new_metadata,
          new_content
        )

      # 5 metadata fields + 1 content field
      assert length(updated_translations) == 6

      Enum.each(updated_translations, fn result ->
        case result do
          {:ok, translation} ->
            assert translation.locale == locale
            assert translation.translatable_id == case_study.id
            assert translation.translatable_type == "case_study"
            field_name = translation.field_name

            expected_value =
              if field_name == "content",
                do: new_content,
                else: new_metadata[String.to_atom(field_name)]

            assert translation.field_value == expected_value

          {:error, changeset} ->
            IO.puts(
              "Error updating translation for field '#{changeset.changes.field_name}': #{inspect(changeset.errors)}"
            )

            flunk(
              "Failed to update translation for field '#{changeset.changes.field_name}': #{inspect(changeset.errors)}"
            )
        end
      end)
    end
  end
end
