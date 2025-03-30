defmodule Portfolio.Content.Entry.Records do
  @moduledoc """
  Provides core database operations for content entries.

  This module handles direct Ecto database interactions for content entries,
  including basic CRUD operations and querying. It focuses on pure database
  operations without business logic, compilation, or translation concerns.

  The module serves as a foundation for higher-level modules that build upon
  these basic database operations to provide more complex functionality.
  """

  alias Portfolio.Repo
  alias Portfolio.Content.Types
  alias Portfolio.Content.Schemas.{Note, CaseStudy}
  alias Portfolio.Content.Entry.AstSerialization
  import Ecto.Query
  require Logger

  @type content_type :: Types.content_type()
  @type id_or_url :: String.t() | integer()

  @doc """
  Gets the schema module for a content type.

  ## Parameters
    - content_type: The type of content to get the schema for

  ## Returns
    - {:ok, schema} if the content type is valid
    - {:error, :invalid_content_type} if the content type is invalid
  """
  @spec get_schema(content_type()) ::
          {:ok, module()} | {:error, :invalid_content_type}
  def get_schema(content_type) do
    case Types.get_schema(content_type) do
      {:error, :invalid_content_type} = error -> error
      schema -> {:ok, schema}
    end
  end

  @doc """
  Applies the appropriate changeset function based on the schema type.

  ## Parameters
    - schema_struct: A struct of the schema to apply the changeset to
    - attrs: A map of attributes to apply to the changeset

  ## Returns
    - An Ecto.Changeset
  """
  @spec apply_changeset(Note.t() | CaseStudy.t() | struct(), map()) ::
          Ecto.Changeset.t()
  def apply_changeset(%Note{} = note, attrs), do: Note.changeset(note, attrs)

  def apply_changeset(%CaseStudy{} = case_study, attrs),
    do: CaseStudy.changeset(case_study, attrs)

  def apply_changeset(struct, attrs) when is_struct(struct) do
    case struct.__struct__ do
      Note ->
        Note.changeset(struct, attrs)

      CaseStudy ->
        CaseStudy.changeset(struct, attrs)

      _ ->
        raise ArgumentError,
              "Unsupported schema struct: #{inspect(struct.__struct__)}"
    end
  end

  @doc """
  Inserts a content entry into the database.

  ## Parameters
    - changeset: An Ecto.Changeset prepared for insertion

  ## Returns
    - {:ok, content} if successful
    - {:error, changeset} if there's an error
  """
  @spec insert_content(Ecto.Changeset.t()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  def insert_content(changeset) do
    Repo.insert(changeset)
  end

  @doc """
  Updates a content entry's basic attributes.

  ## Parameters
    - content: The content entry to update
    - attrs: A map of attributes to update

  ## Returns
    - {:ok, updated_content} if successful
    - {:error, changeset} if there's an error
  """
  @spec update_content_attributes(Note.t() | CaseStudy.t(), map()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  def update_content_attributes(content, attrs) do
    content
    |> Ecto.Changeset.cast(attrs, [
      :title,
      :url,
      :content,
      :is_draft,
      :published_at
    ])
    |> Ecto.Changeset.validate_required([:title, :url, :content])
    |> Repo.update()
  end

  @doc """
  Updates a content entry's AST data.

  ## Parameters
    - content: The content entry to update
    - ast: The AST to store

  ## Returns
    - {:ok, updated_content} if successful
    - {:error, changeset} if there's an error
  """
  @spec update_stored_ast(Note.t() | CaseStudy.t(), list()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  def update_stored_ast(content, ast) when is_list(ast) do
    serialized_ast = AstSerialization.serialize_ast(ast)

    Repo.update(
      Ecto.Changeset.change(content,
        stored_ast: serialized_ast,
        # Set the compiled_content field to nil to indicate we're using AST
        compiled_content: nil
      )
    )
  end

  @doc """
  Deletes a content entry from the database.

  ## Parameters
    - content: The content entry to delete

  ## Returns
    - {:ok, deleted_content} if successful
    - {:error, changeset} if there's an error
  """
  @spec delete_content(Note.t() | CaseStudy.t()) ::
          {:ok, Note.t() | CaseStudy.t()} | {:error, Ecto.Changeset.t()}
  def delete_content(content) do
    Repo.delete(content)
  end

  @doc """
  Retrieves a content entry by ID or URL.

  ## Parameters
    - content_type: The type of content to retrieve
    - id_or_url: The ID or URL of the content to retrieve

  ## Returns
    - The content entry if found

  ## Raises
    - Ecto.NoResultsError if not found
    - ArgumentError if id_or_url format is invalid
  """
  @spec get_content_by_id_or_url(content_type(), id_or_url()) ::
          Note.t() | CaseStudy.t()
  def get_content_by_id_or_url(content_type, id_or_url) do
    case get_schema(content_type) do
      {:ok, schema} ->
        query =
          cond do
            uuid?(id_or_url) ->
              from e in schema, where: e.id == ^id_or_url

            is_binary(id_or_url) ->
              from e in schema, where: e.url == ^id_or_url

            true ->
              raise ArgumentError,
                    "Invalid id_or_url provided: #{inspect(id_or_url)}"
          end

        case Repo.one(query) do
          nil ->
            raise Ecto.NoResultsError, queryable: query

          content ->
            content
        end

      {:error, :invalid_content_type} ->
        raise ArgumentError, "Invalid content type: #{inspect(content_type)}"
    end
  end

  @doc """
  Fetches multiple content items by their IDs.

  ## Parameters
    - ids: A list of content IDs
    - content_type: The type of content to retrieve

  ## Returns
    - {:ok, list_of_content} if successful

  ## Raises
    - Ecto.NoResultsError if no content is found
  """
  @spec fetch_content_items([binary()], content_type()) ::
          {:ok, [Note.t()] | [CaseStudy.t()]}
  def fetch_content_items(ids, content_type) do
    content_schema = Types.get_schema(content_type)
    query = from(c in content_schema, where: c.id in ^ids)

    case Repo.all(query) do
      [] -> raise Ecto.NoResultsError, queryable: query
      content -> {:ok, content}
    end
  end

  @doc """
  Lists content entries of a specific type with optional sorting.

  ## Parameters
    - content_type: The type of content to list
    - opts: Options for sorting (sort_by, sort_order)

  ## Returns
    - A list of content entries
  """
  @spec list_contents(content_type(), keyword()) :: [Note.t()] | [CaseStudy.t()]
  def list_contents(content_type, opts \\ []) do
    case Types.get_schema(content_type) do
      {:error, :invalid_content_type} ->
        # Return empty list for invalid content types
        Logger.warning(
          "Invalid content type provided: #{inspect(content_type)}"
        )

        []

      schema ->
        query =
          from c in schema,
            where: c.is_draft == false and not is_nil(c.published_at)

        query = apply_sorting(query, schema, opts[:sort_by], opts[:sort_order])

        Repo.all(query)
    end
  end

  # Private helper functions

  defp uuid?(string) do
    case UUID.info(string) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp apply_sorting(query, _schema, nil, _), do: query

  defp apply_sorting(query, schema, sort_by, sort_order) do
    valid_fields = schema.__schema__(:fields)

    if sort_by in valid_fields do
      # Default to :asc if no sort_order is provided
      actual_sort_order = sort_order || :asc
      order_by(query, [c], [{^actual_sort_order, field(c, ^sort_by)}])
    else
      Logger.warning(
        "Invalid sort_by field provided: #{inspect(sort_by)}, ignoring."
      )

      # Default to ordering by inserted_at if available, otherwise return as-is
      if :inserted_at in valid_fields do
        order_by(query, [c], asc: c.inserted_at)
      else
        query
      end
    end
  end
end
