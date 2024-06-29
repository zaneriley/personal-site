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
      assert "Title is too long (maximum is 255 characters)" in errors_on(changeset).title
    end


    test "create_note/1 with custom url" do
      attrs = %{title: "Custom URL Test", content: "Content", url: "my-custom-url"}

      assert {:ok, note} = Blog.create_note(attrs)
      assert note.url == "my-custom-url"
    end

    test "create_note/1 with very long custom url" do
      long_url = String.duplicate("a", 300)
      attrs = %{title: "Long Custom URL Test", content: "Content", url: long_url}

      assert {:error, changeset} = Blog.create_note(attrs)
      assert "URL is too long (maximum is 255 characters)" in errors_on(changeset).url
    end
  end
end
