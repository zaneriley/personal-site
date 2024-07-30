defmodule Portfolio.Content.TranslationTest do
  use Portfolio.DataCase
  alias Portfolio.Content
  alias Portfolio.Content.TranslationManager
  alias Portfolio.ContentFixtures

  describe "translation functionality" do
    test "create_or_update_translations creates new translations" do
      note = ContentFixtures.note_fixture()

      attrs = %{
        "title" => "日本語のタイトル",
        "content" => "日本語のコンテンツ",
        "introduction" => "日本語の紹介"
      }

      assert {:ok, translations} =
               TranslationManager.create_or_update_translations(
                 note,
                 "ja",
                 attrs
               )

      assert length(translations) == 3
      assert Enum.all?(translations, &(&1.locale == "ja"))
    end

    test "create_or_update_translations updates existing translations" do
      note = ContentFixtures.note_fixture()
      initial_attrs = %{"title" => "初期タイトル", "content" => "初期コンテンツ"}

      {:ok, _} =
        TranslationManager.create_or_update_translations(
          note,
          "ja",
          initial_attrs
        )

      updated_attrs = %{"title" => "更新されたタイトル", "content" => "更新されたコンテンツ"}

      {:ok, translations} =
        TranslationManager.create_or_update_translations(
          note,
          "ja",
          updated_attrs
        )

      assert length(translations) == 2

      assert Enum.find(translations, &(&1.field_name == "title")).field_value ==
               "更新されたタイトル"

      assert Enum.find(translations, &(&1.field_name == "content")).field_value ==
               "更新されたコンテンツ"
    end

    test "get_translations fetches translations for Japanese locale" do
      case_study = ContentFixtures.case_study_fixture()

      attrs = %{
        "title" => "日本語のタイトル",
        "content" => "日本語のコンテンツ",
        "company" => "日本語の会社名"
      }

      TranslationManager.create_or_update_translations(case_study, "ja", attrs)

      translations =
        TranslationManager.get_translations(case_study.id, "case_study", "ja")

      assert translations["title"] == "日本語のタイトル"
      assert translations["content"] == "日本語のコンテンツ"
      assert translations["company"] == "日本語の会社名"
    end

    test "get_content_with_translations returns content with Japanese translations" do
      case_study = ContentFixtures.case_study_fixture()
      attrs = %{"title" => "翻訳されたタイトル", "content" => "翻訳されたコンテンツ"}
      TranslationManager.create_or_update_translations(case_study, "ja", attrs)

      {:ok, content, translations} =
        Content.get_with_translations("case_study", case_study.url, "ja")

      assert content.id == case_study.id
      assert translations["title"] == "翻訳されたタイトル"
      assert translations["content"] == "翻訳されたコンテンツ"
    end

    test "upsert_from_file creates new content and Japanese translations" do
      attrs = %{
        "url" => "new-note",
        "locale" => "ja",
        "title" => "新しいタイトル",
        "content" => "新しいコンテンツ",
        "introduction" => "新しい紹介"
      }

      assert {:ok, note} = Content.upsert_from_file("note", attrs)
      assert note.url == "new-note"

      {:ok, retrieved_note, translations} =
        Content.get_with_translations("note", "new-note", "ja")

      assert retrieved_note.id == note.id
      assert translations["title"] == "新しいタイトル"
      assert translations["content"] == "新しいコンテンツ"
    end

    test "upsert_from_file updates existing content and Japanese translations" do
      existing_note = ContentFixtures.note_fixture(%{url: "existing-note"})

      attrs = %{
        "url" => "existing-note",
        "locale" => "ja",
        "title" => "更新されたタイトル",
        "content" => "更新されたコンテンツ"
      }

      assert {:ok, updated_note} = Content.upsert_from_file("note", attrs)
      assert updated_note.id == existing_note.id

      {:ok, _, translations} =
        Content.get_with_translations("note", "existing-note", "ja")

      assert translations["title"] == "更新されたタイトル"
      assert translations["content"] == "更新されたコンテンツ"
    end
  end
end
