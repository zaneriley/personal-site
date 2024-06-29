defmodule Portfolio.Blog.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :title, :string
    field :url, :string
    field :read_time, :integer
    field :introduction, :string
    field :file_path, :string
    field :locale, :string
    field :content, :string

    timestamps(type: :utc_datetime)
  end

  @max_title_length 255
  @max_url_length 255

  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :content, :url])
    |> validate_required([:title, :content])
    |> validate_length(:title,
      max: @max_title_length,
      message: "must be at most #{@max_title_length} characters"
    )
    |> ensure_url()
    |> validate_url()
    |> unique_constraint(:url,
      name: :unique_note_urls,
      message: "URL has already been taken"
    )
  end

  defp slugify(string) do
    if String.match?(string, ~r/[\p{Han}\p{Hiragana}\p{Katakana}]/u) do
      string
      |> handle_non_latin()
      |> String.replace(~r/\s+/, "-")
      |> String.replace(~r/-{2,}/, "-")
      |> String.trim("-")
    else
      string
      |> String.downcase()
      |> transliterate()
      |> remove_diacritics()
      |> replace_spaces_and_punctuation()
      |> String.replace(~r/[^\w-]+/, "")
      |> String.replace(~r/-{2,}/, "-")
      |> String.trim("-")
    end
  end

  defp transliterate(string) do
    string
    |> String.replace("æ", "ae")
    |> String.replace("œ", "oe")
    |> String.replace("ß", "ss")
    # Add more transliterations as needed
  end

  defp remove_diacritics(string) do
    string
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-z\s]/u, "")
  end

  defp handle_non_latin(string) do
    # Do nothing for now
    string
  end

  defp replace_spaces_and_punctuation(string) do
    string
    |> String.replace(~r/[[:punct:][:space:]]+/, "-")
  end

  defp ensure_url(changeset) do
    if get_field(changeset, :url) do
      changeset
    else
      generate_url(changeset)
    end
  end

  defp url_missing?(changeset) do
    is_nil(get_field(changeset, :url))
  end

  defp generate_url(changeset) do
    case get_change(changeset, :url) do
      nil ->
        if changeset.valid? do
          title = get_field(changeset, :title)
          url = title |> slugify() |> String.slice(0, @max_url_length)
          put_change(changeset, :url, url)
        else
          changeset
        end
      custom_url ->
        put_change(changeset, :url, String.slice(custom_url, 0, @max_url_length))
    end
  end

  defp validate_url(changeset) do
    changeset
    |> validate_length(:url,
      max: @max_url_length,
      message: "URL is too long (maximum is #{@max_url_length} characters)"
    )
  end
end
