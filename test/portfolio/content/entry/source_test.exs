defmodule Portfolio.Content.Entry.SourceTest do
  use Portfolio.DataCase

  import Portfolio.ContentFixtures

  alias Portfolio.Content.Entry.Source
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Repo

  describe "upsert_from_file/2" do
    test "creates new content from file data" do
      attrs = %{
        "url" => "new-file-note",
        "title" => "New File Note",
        "content" => "Content from file",
        "locale" => "en"
      }

      assert {:ok, %Note{} = note} = Source.upsert_from_file("note", attrs)
      assert note.url == "new-file-note"
      assert note.title == "New File Note"
      assert note.content == "Content from file"
      assert note.stored_ast != nil
    end

    test "updates existing content from file data" do
      existing_note =
        note_fixture(%{"url" => "existing-file-note"},
          publication_generation_id: nil
        )

      attrs = %{
        "url" => "existing-file-note",
        "title" => "Updated File Note",
        "content" => "Updated content from file",
        "locale" => "en"
      }

      assert {:ok, %Note{} = updated_note} =
               Source.upsert_from_file("note", attrs)

      assert updated_note.id == existing_note.id
      assert updated_note.title == "Updated File Note"
      assert updated_note.content == "Updated content from file"
      assert updated_note.stored_ast != nil
    end

    test "does not mutate live-generation content without an explicit generation" do
      live_note =
        note_fixture(%{
          "url" => "live-file-note",
          "title" => "Live File Note",
          "content" => "Live content"
        })

      attrs = %{
        "url" => "live-file-note",
        "title" => "Draft File Note",
        "content" => "Draft content from file",
        "locale" => "en"
      }

      assert {:ok, %Note{} = unpublished_note} =
               Source.upsert_from_file("note", attrs)

      assert unpublished_note.id != live_note.id
      assert unpublished_note.publication_generation_id == nil
      assert Repo.get!(Note, live_note.id).title == "Live File Note"
    end

    test "does not trust publication generation IDs from frontmatter attrs" do
      live_note =
        note_fixture(%{
          "url" => "hostile-frontmatter-note",
          "title" => "Live File Note",
          "content" => "Live content"
        })

      attrs = %{
        "url" => "hostile-frontmatter-note",
        "title" => "Hostile File Note",
        "content" => "Hostile content from file",
        "locale" => "en",
        "publication_generation_id" => live_note.publication_generation_id
      }

      assert {:ok, %Note{} = unpublished_note} =
               Source.upsert_from_file("note", attrs)

      assert unpublished_note.id != live_note.id
      assert unpublished_note.publication_generation_id == nil
      assert Repo.get!(Note, live_note.id).title == "Live File Note"
    end

    test "uses trusted publication generation IDs from promotion code" do
      live_note =
        note_fixture(%{
          "url" => "trusted-generation-note",
          "title" => "Live File Note",
          "content" => "Live content"
        })

      attrs = %{
        "url" => "trusted-generation-note",
        "title" => "Trusted File Note",
        "content" => "Trusted content from file",
        "locale" => "en",
        trusted_publication_generation_id: live_note.publication_generation_id
      }

      assert {:ok, %Note{} = updated_note} =
               Source.upsert_from_file("note", attrs)

      assert updated_note.id == live_note.id

      assert updated_note.publication_generation_id ==
               live_note.publication_generation_id

      assert Repo.get!(Note, live_note.id).title == "Trusted File Note"
    end

    test "handles atom content type" do
      attrs = %{
        "url" => "atom-type-note",
        "title" => "Atom Type Note",
        "content" => "Atom type note content",
        "locale" => "en"
      }

      assert {:ok, %Note{} = note} = Source.upsert_from_file(:note, attrs)
      assert note.url == "atom-type-note"
      assert note.title == "Atom Type Note"
      assert note.stored_ast != nil
    end

    test "returns error for invalid content type" do
      attrs = %{
        "url" => "invalid-type",
        "title" => "Invalid Type",
        "content" => "This should fail",
        "locale" => "en"
      }

      assert {:error, :invalid_content_type} =
               Source.upsert_from_file("invalid_type", attrs)
    end

    test "returns error for nil URL" do
      attrs = %{
        "title" => "No URL",
        "content" => "This should fail",
        "locale" => "en"
      }

      assert {:error, :nil_url} = Source.upsert_from_file("note", attrs)
    end

    test "handles non-default locale translations" do
      # First create the content in the default locale
      {:ok, %Note{} = note} =
        Source.upsert_from_file("note", %{
          "url" => "translatable-note",
          "title" => "English Title",
          "content" => "English Content",
          "locale" => "en"
        })

      # Now add a Japanese translation
      {:ok, %Note{} = translated_note} =
        Source.upsert_from_file("note", %{
          "url" => "translatable-note",
          "title" => "Japanese Title",
          "content" => "Japanese Content",
          "locale" => "ja"
        })

      assert translated_note.id == note.id

      # Get the translations from the database to verify
      translations =
        Portfolio.Content.TranslationRepository.get_translations(
          note.id,
          "note",
          "ja"
        )

      assert translations["title"] == "Japanese Title"
      assert translations["content"] == "Japanese Content"
    end
  end
end
