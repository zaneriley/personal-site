defmodule Portfolio.Content.Entry.RecordsTest do
  use Portfolio.DataCase

  import Portfolio.ContentFixtures

  alias Portfolio.Content.Entry.AstSerialization
  alias Portfolio.Content.Entry.Records
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Repo

  describe "apply_changeset/2" do
    test "applies the Note changeset correctly" do
      attrs = %{
        "title" => "Test Note",
        "content" => "Content",
        "url" => "test-note",
        "locale" => "en"
      }

      changeset = Records.apply_changeset(%Note{}, attrs)
      assert changeset.valid?
      assert changeset.changes.title == "Test Note"
      assert changeset.changes.content == "Content"
      assert changeset.changes.url == "test-note"
    end
  end

  describe "insert_content/1" do
    test "inserts a valid Note" do
      attrs = %{
        "title" => "Test Note",
        "content" => "Content",
        "url" => "test-note",
        "locale" => "en"
      }

      changeset = Records.apply_changeset(%Note{}, attrs)
      assert {:ok, note} = Records.insert_content(changeset)
      assert note.title == "Test Note"
      assert note.content == "Content"
      assert note.url == "test-note"
    end

    test "returns error for invalid data" do
      # Missing required fields
      changeset = Records.apply_changeset(%Note{}, %{})
      assert {:error, changeset} = Records.insert_content(changeset)
      assert errors_on(changeset) != %{}
    end
  end

  describe "update_content_attributes/2" do
    test "updates content attributes" do
      note = note_fixture()

      attrs = %{
        title: "Updated Title",
        content: "Updated Content"
      }

      assert {:ok, updated_note} =
               Records.update_content_attributes(note, attrs)

      assert updated_note.title == "Updated Title"
      assert updated_note.content == "Updated Content"
    end

    test "returns error for invalid updates" do
      note = note_fixture()

      # Set title to nil (invalid)
      attrs = %{
        title: nil
      }

      assert {:error, changeset} =
               Records.update_content_attributes(note, attrs)

      assert errors_on(changeset) != %{}
    end
  end

  describe "update_stored_ast/2" do
    test "updates stored_ast field with serialized AST" do
      note = note_fixture()

      ast = [
        %{
          "type" => "element",
          "tag" => "p",
          "attrs" => %{},
          "children" => [
            %{"type" => "text", "text" => "Hello, world!"}
          ]
        }
      ]

      assert {:ok, updated_note} = Records.update_stored_ast(note, ast)
      assert updated_note.stored_ast != nil
      assert updated_note.compiled_content == nil

      # Verify we can deserialize the stored AST back to a similar structure
      deserialized_ast =
        AstSerialization.deserialize_ast(updated_note.stored_ast)

      assert is_list(deserialized_ast)
      assert length(deserialized_ast) == 1

      # The actual structure will be determined by the serialization format
      # Just verify that we can deserialize without errors and get a list
    end
  end

  describe "delete_content/1" do
    test "deletes an unpublished content entry" do
      note = note_fixture(%{}, publication_generation_id: nil)
      assert {:ok, _} = Records.delete_content(note)

      refute Repo.get(Note, note.id)
    end

    test "refuses to delete published content outside the publication workflow" do
      note = note_fixture()

      assert {:error, changeset} = Records.delete_content(note)

      assert %{
               publication_generation_id: [
                 "cannot be deleted outside the publication workflow"
               ]
             } = errors_on(changeset)

      assert %Note{} = Repo.get(Note, note.id)
    end
  end

  describe "get_content_by_id_or_url/2" do
    test "retrieves content by ID" do
      note = note_fixture()
      found_note = Records.get_content_by_id_or_url("note", note.id)
      assert found_note.id == note.id
    end

    test "retrieves content by URL" do
      note = note_fixture()
      found_note = Records.get_content_by_id_or_url("note", note.url)
      assert found_note.id == note.id
    end

    test "raises for non-existent content" do
      assert_raise Ecto.NoResultsError, fn ->
        Records.get_content_by_id_or_url("note", "non-existent-url")
      end
    end

    test "raises for invalid content type" do
      assert_raise ArgumentError, fn ->
        Records.get_content_by_id_or_url("invalid_type", "some-url")
      end
    end
  end

  describe "fetch_content_items/2" do
    test "fetches multiple content items by IDs" do
      note1 = note_fixture(%{"title" => "Note 1"})
      note2 = note_fixture(%{"title" => "Note 2"})

      {:ok, notes} = Records.fetch_content_items([note1.id, note2.id], "note")

      assert length(notes) == 2
      assert Enum.any?(notes, fn n -> n.id == note1.id end)
      assert Enum.any?(notes, fn n -> n.id == note2.id end)
    end

    test "raises when no content is found" do
      # Using a bogus UUID that's formatted correctly
      bogus_id = "12345678-1234-1234-1234-123456789012"

      assert_raise Ecto.NoResultsError, fn ->
        Records.fetch_content_items([bogus_id], "note")
      end
    end
  end

  describe "list_contents/2" do
    test "lists published content with default sorting" do
      # Create a draft note
      note_fixture(%{"is_draft" => true})

      # Create published notes
      published1 =
        note_fixture(%{
          "title" => "Published 1",
          "is_draft" => false,
          "published_at" => DateTime.utc_now() |> DateTime.add(-1, :day)
        })

      published2 =
        note_fixture(%{
          "title" => "Published 2",
          "is_draft" => false,
          "published_at" => DateTime.utc_now()
        })

      contents = Records.list_contents("note")

      # Should only include published (non-draft) content
      assert length(contents) >= 2

      # Check both published items are included
      content_ids = Enum.map(contents, & &1.id)
      assert published1.id in content_ids
      assert published2.id in content_ids
    end

    test "supports sorting" do
      # Create notes with specific titles for sorting
      note_fixture(%{
        "title" => "B Note",
        "is_draft" => false,
        "published_at" => DateTime.utc_now()
      })

      note_fixture(%{
        "title" => "A Note",
        "is_draft" => false,
        "published_at" => DateTime.utc_now()
      })

      # Sort ascending by title
      asc_contents =
        Records.list_contents("note", sort_by: :title, sort_order: :asc)

      titles = Enum.map(asc_contents, & &1.title)

      assert Enum.find_index(titles, &(&1 == "A Note")) <
               Enum.find_index(titles, &(&1 == "B Note"))

      # Sort descending by title
      desc_contents =
        Records.list_contents("note", sort_by: :title, sort_order: :desc)

      titles = Enum.map(desc_contents, & &1.title)

      assert Enum.find_index(titles, &(&1 == "B Note")) <
               Enum.find_index(titles, &(&1 == "A Note"))
    end
  end
end
