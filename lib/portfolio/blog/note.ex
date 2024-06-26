defmodule Portfolio.Blog.Note do
  @moduledoc """
  Defines the schema and changeset for `notes` in the blog portfolio.

  The `Note` schema represents a blog note with a title, content, and a unique URL.
  It includes functionality to handle creation and updates with automatic timestamps.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :title, :string
    field :content, :string
    field :url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :content])
    |> validate_required([:title, :content])
    |> unique_constraint(:url)
  end
end
