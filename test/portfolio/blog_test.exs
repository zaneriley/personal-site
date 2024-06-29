defmodule Portfolio.BlogTest do
  use Portfolio.DataCase

  alias Portfolio.Blog
  alias Portfolio.BlogFixtures

  describe "notes" do
    test "create_note/1 with valid data creates a note" do
      valid_attrs = %{title: "Test Note", content: "This is a test note.", url: "test-note"}
      assert {:ok, note} = Blog.create_note(valid_attrs)
      assert note.title == "Test Note"
      assert note.content == "This is a test note."
      assert note.url == "test-note"
    end
  end
end
