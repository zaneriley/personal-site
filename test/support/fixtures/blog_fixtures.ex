defmodule Portfolio.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Portfolio.Blog` context.
  """

  @doc """
  Generate a note.
  """
  def note_fixture(attrs \\ %{}) do
    IO.inspect(attrs, label: "Fixture attrs")
    {:ok, note} =
      attrs
      |> Enum.into(%{
        title: "some title",
        content: "some content",
        url: "test-note"
      })
      |> IO.inspect(label: "Merged attrs")
      |> Portfolio.Blog.create_note()

    IO.inspect(note, label: "Created note")
    note
  end
end
