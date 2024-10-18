defmodule Portfolio.Content.ContentTest do
  use Portfolio.DataCase
  alias Portfolio.Content
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.ContentFixtures
  alias Portfolio.Content.TranslationManager
  require Logger

  describe "content retrieval" do
    test "get!/2 returns the content item with given id" do
      note = ContentFixtures.note_fixture()
      retrieved_note = Content.get!("note", note.id)
      assert retrieved_note.id == note.id
      assert retrieved_note.title == note.title
      assert retrieved_note.content == note.content
      assert is_binary(retrieved_note.compiled_content)
    end

    test "get!/2 returns the content item with given url" do
      note = ContentFixtures.note_fixture()
      retrieved_note = Content.get!("note", note.url)
      assert retrieved_note.id == note.id
      assert retrieved_note.title == note.title
      assert retrieved_note.content == note.content
      assert is_binary(retrieved_note.compiled_content)
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

      updated_note = Content.get!("note", note.id)
      assert note.id == updated_note.id
      assert note.title == updated_note.title
      assert note.content == updated_note.content
      assert is_binary(updated_note.compiled_content)
    end
  end

  describe "content change" do
    test "change/3 returns error for invalid content type" do
      assert {:error, :invalid_content_type} =
               Content.change("invalid_type", %{}, %{})
    end

    test "change/3 returns changeset for valid content type" do
      note = ContentFixtures.note_fixture()

      assert %Ecto.Changeset{} =
               Content.change("note", note, %{title: "New Title"})
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
    setup do
      Portfolio.DataCase.clear_cache()
      :ok
    end

    test "get_with_translations/3 returns content with specified locale translations" do
      # Create a note in the default locale (English)
      {:ok, note} =
        Content.create("note", %{
          "title" => "English Title",
          "content" => "English Content",
          "url" => "test-note-with-translations",
          "locale" => "en"
        })

      # Add a French translation
      {:ok, french_translation} =
        Content.upsert_from_file("note", %{
          "title" => "Titre Français",
          "url" => "test-note-with-translations",
          "locale" => "fr"
        })

      Logger.debug("French translation created: #{inspect(french_translation)}")

      # Retrieve the note with French translations
      {:ok, retrieved_note, translations, compiled_content} =
        Content.get_with_translations("note", note.url, "fr")

      Logger.debug("Retrieved translations: #{inspect(translations)}")

      # Assertions
      assert retrieved_note.id == note.id
      assert retrieved_note.title == "English Title"
      assert translations["title"] == "Titre Français"
      assert translations["url"] == "test-note-with-translations"
      assert is_binary(compiled_content)
    end

    test "get_with_translations handles partial translations" do
      # Create a note
      {:ok, note} =
        Content.create("note", %{
          "title" => "English Title",
          "content" => "English Content",
          "url" => "partial-translation-note",
          "locale" => "en"
        })

      # Create partial translation
      {:ok, _} =
        Content.upsert_from_file("note", %{
          "title" => "部分的な日本語のタイトル",
          "url" => "partial-translation-note",
          "locale" => "ja"
        })

      # Retrieve content with translations
      {:ok, _content, translations, _compiled_content} =
        Content.get_with_translations("note", note.url, "ja")

      # Assertions
      assert translations["title"] == "部分的な日本語のタイトル"
      assert Map.has_key?(translations, "content") == false
    end

    test "get_content_with_translations returns default content for unsupported locale" do
      note = ContentFixtures.note_fixture()
      # Assuming Spanish translations are not provided
      unsupported_locale = "es"

      {:ok, content, translations, _compiled_content} =
        Content.get_with_translations("note", note.url, unsupported_locale)

      # Assuming English is the default
      assert content.locale == "en"
      assert Map.keys(translations) == []
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
      existing_note =
        ContentFixtures.note_fixture(%{"url" => "existing-file-note"})

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

    test "upsert_from_file/2 handles atom content type" do
      attrs = %{
        "url" => "atom-type-note",
        "locale" => "en",
        "title" => "Atom Type Note",
        "content" => "Atom type note content"
      }

      assert {:ok, %Note{}} = Content.upsert_from_file(:note, attrs)
    end
  end

  describe "error handling" do
    test "get!/2 raises InvalidContentTypeError for invalid content type" do
      assert_raise Content.InvalidContentTypeError, fn ->
        Content.get!("invalid_type", "some-id")
      end
    end

    test "create/2 returns error for invalid content type" do
      assert {:error, :invalid_content_type} =
               Content.create("invalid_type", %{title: "Test"})
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

    test "get_with_translations/3 returns content with specified locale translations" do
      # Create a note manually
      {:ok, note} =
        Content.create("note", %{
          "title" => "English Title",
          "content" => "English Content",
          "url" => "test-note",
          "locale" => "en"
        })

      # Create translations manually
      TranslationManager.create_or_update_translations(note, "fr", %{
        "title" => "Titre Français",
        "content" => "Contenu Français"
      })

      # Call get_with_translations
      {:ok, retrieved_note, translations, compiled_content} =
        Content.get_with_translations("note", note.url, "fr")

      # Assertions
      assert retrieved_note.id == note.id
      assert translations["title"] == "Titre Français"

      # Use Floki to extract text content
      html_content = translations["content"]
      text_content = Floki.text(html_content)

      assert text_content == "Contenu Français"
      assert is_binary(compiled_content)
    end
  end

  describe "translation management" do
    test "handle concurrent updates to translations" do
      note = ContentFixtures.note_fixture()
      attrs1 = %{"title" => "タイトル1"}
      attrs2 = %{"title" => "タイトル2"}

      Task.async(fn ->
        Content.TranslationManager.create_or_update_translations(
          note,
          "ja",
          attrs1
        )
      end)

      Task.async(fn ->
        Content.TranslationManager.create_or_update_translations(
          note,
          "ja",
          attrs2
        )
      end)

      # Allow tasks to complete
      Process.sleep(100)

      translations =
        Content.TranslationManager.get_translations(note.id, "note", "ja")

      assert translations["title"] in ["タイトル1", "タイトル2"]
    end
  end
end
