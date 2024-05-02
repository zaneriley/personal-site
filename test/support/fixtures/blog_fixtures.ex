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
        content: "some content",
        title: "some title"
      })
      |> Portfolio.Blog.create_note()

    note
  end
end
