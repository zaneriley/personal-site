defmodule Portfolio.BlogTest do
  use Portfolio.DataCase
  alias Portfolio.Blog
  alias Portfolio.BlogFixtures

  describe "notes" do
    test "create_note/1 with valid data creates a note" do
      valid_attrs = %{
        title: "Test Note",
        content: "This is a test note.",
        url: "test-note"
      }

      assert {:ok, note} = Blog.create_note(valid_attrs)
      assert note.title == "Test Note"
      assert note.content == "This is a test note."
      assert note.url == "test-note"
    end

    test "create_note/1 with very long title" do
      long_title = String.duplicate("a", 1000)
      attrs = %{title: long_title, content: "Content"}

      assert {:error, changeset} = Blog.create_note(attrs)

      assert "must be at most 255 characters" in errors_on(changeset).title
    end

    test "create_note/1 with custom url" do
      attrs = %{
        title: "Custom URL Test",
        content: "Content",
        url: "my-custom-url"
      }

      assert {:ok, note} = Blog.create_note(attrs)
      assert note.url == "my-custom-url"
    end

    test "create_note/1 with very long custom url" do
      long_url = String.duplicate("a", 300)

      attrs = %{
        title: "Long Custom URL Test",
        content: "Content",
        url: long_url
      }

      assert {:error, changeset} = Blog.create_note(attrs)

      assert "URL is too long (maximum is 255 characters)" in errors_on(
               changeset
             ).url
    end

    test "create_note/1 with duplicate URLs" do
      attrs1 = %{title: "First Post", content: "Content 1", url: "my-post"}
      attrs2 = %{title: "Second Post", content: "Content 2", url: "my-post"}

      assert {:ok, _note1} = Blog.create_note(attrs1)

      assert {:error, changeset} = Blog.create_note(attrs2)
      assert {"URL has already been taken", _} = changeset.errors[:url]
    end

    test "create_note/1 with potentially unsafe content" do
      attrs = %{
        title: "Unsafe Content",
        content: "<script>alert('XSS')</script>",
        url: "unsafe-content"
      }

      assert {:ok, note} = Blog.create_note(attrs)
      assert note.content == "<script>alert('XSS')</script>"
      # Note: We're not sanitizing content in the current implementation
    end

    test "create_note/1 with Japanese characters in title" do
      attrs = %{title: "特殊文字 テスト", content: "Content"}

      assert {:ok, note} = Blog.create_note(attrs)
      assert note.url == "特殊文字-テスト"
    end

    test "update_note/2 preserves original URL" do
      {:ok, note} =
        Blog.create_note(%{title: "Original Title", content: "Content"})

      original_url = note.url

      {:ok, updated_note} = Blog.update_note(note, %{title: "New Title"})
      assert updated_note.url == original_url
    end

    test "get_note!/1 with non-existent URL" do
      assert_raise Ecto.NoResultsError, fn ->
        Blog.get_note!("non-existent-url")
      end
    end
  end

  describe "notes listing and retrieval" do
    test "list_notes/0 returns all notes in correct order" do
      # Create three notes with known creation times
      {:ok, note1} =
        Blog.create_note(%{title: "First Note", content: "Content 1"})

      # Ensure different timestamps
      :timer.sleep(1000)

      {:ok, note2} =
        Blog.create_note(%{title: "Second Note", content: "Content 2"})

      :timer.sleep(1000)

      {:ok, note3} =
        Blog.create_note(%{title: "Third Note", content: "Content 3"})

      # Retrieve the list of notes
      notes = Blog.list_notes()

      # Assert the correct number of notes
      assert length(notes) == 3

      # Assert the correct order (most recent first)
      assert [note3.id, note2.id, note1.id] == Enum.map(notes, & &1.id)

      # Assert all notes are present with correct attributes
      assert Enum.all?(notes, fn note ->
               Enum.any?([note1, note2, note3], fn created_note ->
                 note.id == created_note.id &&
                   note.title == created_note.title &&
                   note.content == created_note.content &&
                   note.url == created_note.url
               end)
             end)
    end

    test "get_note!/1 retrieves note by ID and URL with special characters" do
      # Create a note with special characters
      attrs = %{
        title: "Special 特殊 Note!",
        content: "Content with 特殊文字 and 🚀",
        url: "special-note"
      }

      {:ok, created_note} = Blog.create_note(attrs)

      # Retrieve note by ID
      retrieved_by_id = Blog.get_note!(created_note.id)
      assert retrieved_by_id.id == created_note.id
      assert retrieved_by_id.title == attrs.title
      assert retrieved_by_id.content == attrs.content
      assert retrieved_by_id.url == attrs.url

      # Retrieve note by URL
      retrieved_by_url = Blog.get_note!(attrs.url)
      assert retrieved_by_url.id == created_note.id
      assert retrieved_by_url.title == attrs.title
      assert retrieved_by_url.content == attrs.content
      assert retrieved_by_url.url == attrs.url

      # Assert retrievals by ID and URL return the same note
      assert retrieved_by_id == retrieved_by_url

      # Test non-existent note
      assert_raise Ecto.NoResultsError, fn ->
        Blog.get_note!("non-existent")
      end
    end
  end
end
