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
      {:ok, note} = Blog.create_note(%{title: "Original Title", content: "Content"})
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
end
