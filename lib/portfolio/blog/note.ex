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
    |> cast(attrs, [:title, :content, :url])
    |> validate_required([:title, :content])
    |> generate_url()
    |> unique_constraint(:url)
  end

  defp slugify(str) when is_binary(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/[\s-]+/, "-")
    |> String.trim("-")
  end

  defp slugify(_), do: ""

  defp generate_url(changeset) do
    case get_change(changeset, :url) do
      nil ->
        title = get_field(changeset, :title)
        put_change(changeset, :url, slugify(title))

      custom_url ->
        put_change(changeset, :url, slugify(custom_url))
    end
  end
end
