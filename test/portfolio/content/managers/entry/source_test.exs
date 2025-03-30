defmodule Portfolio.Content.Managers.Entry.SourceTest do
  use Portfolio.DataCase

  alias Portfolio.Content.Managers.Entry.Source
  alias Portfolio.Content.Schemas.{Note, CaseStudy}
  alias Portfolio.ContentFixtures

  describe "upsert_from_file/2" do
    test "creates new content from file data" do
      attrs = %{
        "url" => "new-file-note",
        "locale" => "en",
        "title" => "New File Note",
        "content" => "Content from file"
      }

      assert {:ok, %Note{} = note} = Source.upsert_from_file("note", attrs)
      assert note.url == "new-file-note"
      assert note.title == "New File Note"
      assert note.content == "Content from file"
      assert note.stored_ast != nil
    end

    test "updates existing content from file data" do
      existing_note =
        ContentFixtures.note_fixture(%{"url" => "existing-file-note"})

      attrs = %{
        "url" => "existing-file-note",
        "locale" => "en",
        "title" => "Updated File Note",
        "content" => "Updated content from file"
      }

      assert {:ok, %Note{} = updated_note} =
               Source.upsert_from_file("note", attrs)

      assert updated_note.id == existing_note.id
      assert updated_note.title == "Updated File Note"
      assert updated_note.content == "Updated content from file"
      assert updated_note.stored_ast != nil
    end

    test "handles atom content type" do
      attrs = %{
        "url" => "atom-type-note",
        "locale" => "en",
        "title" => "Atom Type Note",
        "content" => "Atom type note content"
      }

      assert {:ok, %Note{} = note} = Source.upsert_from_file(:note, attrs)
      assert note.title == "Atom Type Note"
      assert note.stored_ast != nil
    end

    test "returns error for invalid content type" do
      attrs = %{
        "url" => "invalid-type",
        "locale" => "en",
        "title" => "Invalid Type",
        "content" => "This should fail"
      }

      assert {:error, :invalid_content_type} =
               Source.upsert_from_file("invalid_type", attrs)
    end

    test "returns error for nil URL" do
      attrs = %{
        "locale" => "en",
        "title" => "No URL",
        "content" => "This should fail"
      }

      assert {:error, :nil_url} = Source.upsert_from_file("note", attrs)
    end

    test "handles non-default locale translations" do
      # First create the content in the default locale
      {:ok, note} =
        Source.upsert_from_file("note", %{
          "url" => "translatable-note",
          "locale" => "en",
          "title" => "English Title",
          "content" => "English Content"
        })

      # Now add a Japanese translation
      attrs = %{
        "url" => "translatable-note",
        "locale" => "ja",
        "title" => "日本語のタイトル"
      }

      assert {:ok, _} = Source.upsert_from_file("note", attrs)

      # Get the translations from the database to verify
      translations =
        Portfolio.Content.TranslationManager.get_translations(
          note.id,
          "note",
          "ja"
        )

      assert translations["title"] == "日本語のタイトル"
    end
  end
end
