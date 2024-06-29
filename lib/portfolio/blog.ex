defmodule Portfolio.Blog do
  @moduledoc """
  The Blog context.
  """
  require Logger
  import Ecto.Query, warn: false
  alias Portfolio.Repo
  alias Portfolio.Blog.Note

  @doc """
  Returns the list of notes.

  ## Examples

      iex> list_notes()
      [%Note{}, ...]

  """
  def list_notes do
    Repo.all(Note)
    |> Enum.map(fn note ->
      url = note.url || "note-#{note.id}"
      %{note | url: url}
    end)
  end

  @doc """
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ## Examples

      iex> get_note!(123)
      %Note{}

      iex> get_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_note!(url_or_id) do
    case Integer.parse(url_or_id) do
      {id, _} -> Repo.get!(Note, id)
      :error -> Repo.get_by!(Note, url: url_or_id)
    end
  end

  @doc """
  Creates a note.

  ## Examples

      iex> create_note(%{field: value})
      {:ok, %Note{}}

      iex> create_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_note(attrs \\ %{}) do
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, note} ->
        Logger.info("Note created successfully: #{note.id}")
        {:ok, note}
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Failed to create note: #{inspect(changeset.errors)}")
        {:error, changeset}
      {:error, %Ecto.ConstraintError{} = error} ->
        Logger.error("Constraint error: #{inspect(error)}")
        changeset = Note.changeset(%Note{}, attrs)
        {:error, Ecto.Changeset.add_error(changeset, :url, "has already been taken")}
    end
  end

  @doc """
  Updates a note.

  ## Examples

      iex> update_note(note, %{field: new_value})
      {:ok, %Note{}}

      iex> update_note(note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a note.

  ## Examples

      iex> delete_note(note)
      {:ok, %Note{}}

      iex> delete_note(note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.

  ## Examples

      iex> change_note(note)
      %Ecto.Changeset{data: %Note{}}

  """
  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end
end
