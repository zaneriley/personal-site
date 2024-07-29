defmodule Portfolio.Content.ContentTest do
  use Portfolio.DataCase
  alias Portfolio.Content
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.ContentFixtures


  describe "content retrieval" do
    test "get!/2 returns the content item with given id" do
      note = ContentFixtures.note_fixture()
      assert Content.get!("note", note.id) == note
    end

    test "get!/2 returns the content item with given url" do
      note = ContentFixtures.note_fixture()
      assert Content.get!("note", note.url) == note
    end

    test "get!/2 raises Ecto.NoResultsError for non-existent content" do
      assert_raise Ecto.NoResultsError, fn ->
        Content.get!("note", Ecto.UUID.generate())
      end
    end

    test "get!/2 raises ArgumentError for invalid id_or_url" do
      assert_raise ArgumentError, fn ->
        Content.get!("note", 123)
      end
    end
  end

  describe "content creation" do
    test "create/2 with valid data creates a note" do
      valid_attrs = %{
        "title" => "New Note",
        "content" => "Some content",
        "url" => "new-note",
        "locale" => "en"
      }

      assert {:ok, %Note{} = note} = Content.create("note", valid_attrs)
      assert note.title == "New Note"
      assert note.content == "Some content"
      assert note.url == "new-note"
    end

    test "create/2 with invalid content_type returns error" do
      invalid_attrs = %{
        "content_type" => "invalid",
        "title" => "Test",
        "content" => "Content",
        "locale" => "en"
      }

      assert {:error, :invalid_content_type} =
               Content.create("invalid", invalid_attrs)
    end

  end

  describe "content update" do
    test "update/3 with valid data updates the note" do
      note = ContentFixtures.note_fixture()
      update_attrs = %{"title" => "Updated Title"}

      assert {:ok, %Note{} = updated_note} =
               Content.update("note", note, update_attrs)

      assert updated_note.title == "Updated Title"
    end

    test "update/3 with invalid data returns error changeset" do
      note = ContentFixtures.note_fixture()
      invalid_attrs = %{"title" => nil}

      assert {:error, %Ecto.Changeset{}} =
               Content.update("note", note, invalid_attrs)

      assert note == Content.get!("note", note.id)
    end
  end

  describe "content deletion" do
    test "delete/2 deletes the note" do
      note = ContentFixtures.note_fixture()
      assert {:ok, %Note{}} = Content.delete("note", note)
      assert_raise Ecto.NoResultsError, fn -> Content.get!("note", note.id) end
    end
  end

  describe "content with translations" do
    test "get_with_translations/3 returns content with translations" do
      case_study = ContentFixtures.case_study_fixture()

      {:ok, _translations} =
        Content.TranslationManager.create_or_update_translations(
          case_study,
          "ja",
          %{"title" => "日本語のタイトル", "content" => "日本語のコンテンツ"}
        )

      assert {:ok, retrieved_case_study, translations} =
               Content.get_with_translations("case_study", case_study.url, "ja")

      assert retrieved_case_study.id == case_study.id
      assert translations["title"] == "日本語のタイトル"
      assert translations["content"] == "日本語のコンテンツ"
    end
  end

  describe "file-based operations" do
    test "upsert_from_file/2 creates new content from file data" do
      attrs = %{
        "url" => "new-file-note",
        "locale" => "en",
        "title" => "New File Note",
        "content" => "Content from file"
      }

      assert {:ok, %Note{} = note} = Content.upsert_from_file("note", attrs)
      assert note.url == "new-file-note"
      assert note.title == "New File Note"
    end

    test "upsert_from_file/2 updates existing content from file data" do
      existing_note = ContentFixtures.note_fixture(%{"url" => "existing-file-note"})

      attrs = %{
        "url" => "existing-file-note",
        "locale" => "en",
        "title" => "Updated File Note",
        "content" => "Updated content from file"
      }

      assert {:ok, %Note{} = updated_note} =
               Content.upsert_from_file("note", attrs)

      assert updated_note.id == existing_note.id
      assert updated_note.title == "Updated File Note"
    end
  end

  describe "locale handling" do
    test "extract_locale/1 extracts locale from valid file path" do
      file_path = "priv/content/note/en/example.md"
      assert {:ok, "en"} = Content.extract_locale(file_path)
    end

    test "extract_locale/1 returns error for invalid file path" do
      file_path = "invalid/path/example.md"
      assert {:error, :invalid_file_path} = Content.extract_locale(file_path)
    end
  end
end
