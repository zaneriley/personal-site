defmodule Portfolio.Blog do
  @moduledoc """
  The Blog context.
  """
  require Logger
  import Ecto.Query, warn: false
  alias Portfolio.Repo
  alias Portfolio.Blog.Note

  @type list_notes_option :: {:order, :asc | :desc} | {:limit, non_neg_integer() | nil}

  @doc """
  Returns the list of notes.

  ## Options

    * `:order` - The order to return notes in. Can be `:asc` or `:desc`. Defaults to `:desc`.
    * `:limit` - The maximum number of notes to return. Defaults to `nil` (no limit).

  ## Examples

      iex> list_notes()
      [%Note{}, ...]

      iex> list_notes(order: :asc, limit: 10)
      [%Note{}, ...]

  """
  @spec list_notes([list_notes_option]) :: [%Note{}]
  def list_notes(opts \\ []) do
    opts = Keyword.merge([order: :desc, limit: nil], opts)

    query = from(n in Note, order_by: [{^opts[:order], :inserted_at}])
    query = if opts[:limit], do: limit(query, ^opts[:limit]), else: query

    Repo.all(query)
    |> process_results()
  end

  @spec process_results([%Note{}]) :: [%Note{}]
  defp process_results(notes) do
    Enum.map(notes, fn note ->
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
  @spec get_note!(integer() | String.t()) :: %Note{} | no_return()
  def get_note!(id_or_url) do
    note =
      case id_or_url do
        id when is_integer(id) ->
          # Direct query by ID for integer input
          Repo.get(Note, id)

        url when is_binary(url) ->
          # Attempt to parse string as integer, fall back to URL lookup
          case Integer.parse(url) do
            {id, ""} -> Repo.get(Note, id)
            _ -> Repo.get_by(Note, url: url)
          end
      end

    case note do
      nil -> raise Ecto.NoResultsError, queryable: Note
      note -> note
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
    changeset = Note.changeset(%Note{}, attrs)
    insert_result = Repo.insert(changeset)

    case insert_result do
      {:ok, note} ->
        Logger.info("Note created successfully: #{note.id}")
        {:ok, note}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Failed to create note: #{inspect(changeset.errors)}")
        {:error, changeset}

      {:error, %Ecto.ConstraintError{} = error} ->
        Logger.error("Constraint error: #{inspect(error)}")
        changeset = Note.changeset(%Note{}, attrs)

        {:error,
         Ecto.Changeset.add_error(changeset, :url, "has already been taken")}
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
