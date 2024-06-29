defmodule Portfolio.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Portfolio.Blog` context.
  """

  @doc """
  Generate a note.
  """
  def note_fixture(attrs \\ %{}) do
    {:ok, note} =
      attrs
      |> Enum.into(%{
        title: "some title",
        content: "some content",
        url: "test-note"
      })
      |> Portfolio.Blog.create_note()

    note
  end
end
