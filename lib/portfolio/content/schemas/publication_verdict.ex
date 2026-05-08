defmodule Portfolio.Content.Schemas.PublicationVerdict do
  @moduledoc """
  Records the app's verdict for a content repository commit.

  A verdict is the durable answer to the authoring question: did this content
  commit become live, get rejected, or get ignored as irrelevant to publishing?
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]
  @statuses ~w(accepted rejected ignored)
  @path_fields [:promoted_paths, :removed_paths, :skipped_paths]

  @type t :: %__MODULE__{}

  schema "content_publication_verdicts" do
    field :content_sha, :string
    field :status, :string
    field :reason, :string
    field :promoted_paths, {:array, :string}, default: []
    field :removed_paths, {:array, :string}, default: []
    field :skipped_paths, {:array, :string}, default: []
    field :error_details, :map, default: %{}

    timestamps()
  end

  @spec statuses() :: [String.t()]
  def statuses, do: @statuses

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(verdict, attrs) do
    verdict
    |> cast(attrs, [
      :content_sha,
      :status,
      :reason,
      :promoted_paths,
      :removed_paths,
      :skipped_paths,
      :error_details
    ])
    |> validate_required([
      :content_sha,
      :status,
      :promoted_paths,
      :removed_paths,
      :skipped_paths,
      :error_details
    ])
    |> validate_format(:content_sha, ~r/\A[0-9a-f]{40}\z/i)
    |> validate_inclusion(:status, @statuses)
    |> validate_path_lists()
    |> unique_constraint(:content_sha)
  end

  defp validate_path_lists(changeset) do
    Enum.reduce(@path_fields, changeset, &validate_path_list/2)
  end

  defp validate_path_list(field, changeset) do
    validate_change(changeset, field, fn ^field, paths ->
      path_list_errors(field, paths)
    end)
  end

  defp path_list_errors(field, paths) do
    if Enum.all?(paths, &is_binary/1) do
      []
    else
      [{field, "must contain only strings"}]
    end
  end
end
