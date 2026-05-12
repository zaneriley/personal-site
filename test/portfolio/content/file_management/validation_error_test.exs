defmodule Portfolio.Content.FileManagement.ValidationErrorTest do
  use ExUnit.Case, async: true

  alias Portfolio.Content.FileManagement.ValidationError
  alias Portfolio.Content.Schemas.Note

  describe "messages/1" do
    test "expands changeset field errors" do
      changeset =
        Note.changeset(%Note{}, %{
          "content" => "Body",
          "locale" => "en"
        })

      assert ValidationError.messages(changeset) == ["title: can't be blank"]
    end

    test "humanizes alias collision reasons" do
      assert ValidationError.messages({:duplicate_alias, "old-note"}) == [
               "aliases: old-note is used by more than one content file"
             ]

      assert ValidationError.message({:alias_conflicts_with_url, "old-note"}) ==
               "aliases: old-note conflicts with a canonical URL"
    end
  end
end
