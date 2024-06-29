defmodule Portfolio.Blog.Note do
  @moduledoc """
  Defines the schema and changeset for `notes` in the blog portfolio.

  The `Note` schema represents a blog note with a title, content, and a unique URL.
  It includes functionality to handle creation and updates with automatic timestamps.
  """
use Ecto.Schema
import Ecto.Changeset
import Slug, only: [slugify: 1]

schema "notes" do
  field :title, :string
  field :content, :string
  field :url, :string

  timestamps(type: :utc_datetime)
end

@max_title_length 255
@max_url_length 255

def changeset(note, attrs) do
  note
  |> cast(attrs, [:title, :content, :url])
  |> validate_required([:title, :content])
  |> validate_title_length()
  |> validate_format(:url, ~r/^[a-z0-9\-]+$/, message: "must contain only lowercase letters, numbers, and hyphens")
  |> validate_length(:url, max: @max_url_length, message: "URL is too long (maximum is #{@max_url_length} characters)")
  |> generate_url()
  |> unique_constraint(:url)
end

defp validate_title_length(changeset) do
  validate_length(changeset, :title, max: @max_title_length,
    message: "Title is too long (maximum is #{@max_title_length} characters)")
end

defp generate_url(changeset) do
  case get_change(changeset, :url) do
    nil ->
      if changeset.valid? do
        title = get_field(changeset, :title)
        url = title |> Slug.slugify() |> String.slice(0, @max_url_length)
        put_change(changeset, :url, url)
      else
        changeset
      end
    custom_url ->
      put_change(changeset, :url, String.slice(custom_url, 0, @max_url_length))
  end
end
end
