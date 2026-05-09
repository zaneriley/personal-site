defmodule Portfolio.Content.Schemas.PublicationLedgerEntry do
  @moduledoc """
  Append-only record of a content publication delivery verdict.

  The `github_delivery_id` is the idempotency boundary for webhook deliveries.
  The `content_sha` is intentionally not unique: the same commit can be accepted,
  rolled back to, or redelivered over time.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Portfolio.Content.Schemas.PublicationGeneration

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]
  @statuses ~w(accepted rejected ignored duplicate rollback)
  @path_fields [:promoted_paths, :removed_paths, :skipped_paths]

  @type t :: %__MODULE__{}

  schema "content_publication_ledger" do
    field :github_delivery_id, :string
    field :content_sha, :string
    field :status, :string
    field :repository, :string
    field :ref, :string
    field :reason, :string
    field :promoted_paths, {:array, :string}, default: []
    field :removed_paths, {:array, :string}, default: []
    field :skipped_paths, {:array, :string}, default: []
    field :structured_errors, :map, default: %{}
    field :received_at, :utc_datetime_usec
    field :started_at, :utc_datetime_usec
    field :finished_at, :utc_datetime_usec

    belongs_to :generation, PublicationGeneration,
      foreign_key: :content_publication_generation_id

    timestamps()
  end

  @spec statuses() :: [String.t()]
  def statuses, do: @statuses

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :github_delivery_id,
      :content_sha,
      :status,
      :repository,
      :ref,
      :reason,
      :content_publication_generation_id,
      :promoted_paths,
      :removed_paths,
      :skipped_paths,
      :structured_errors,
      :received_at,
      :started_at,
      :finished_at
    ])
    |> validate_required([
      :github_delivery_id,
      :content_sha,
      :status,
      :promoted_paths,
      :removed_paths,
      :skipped_paths,
      :structured_errors
    ])
    |> validate_format(:content_sha, ~r/\A[0-9a-f]{40}\z/i)
    |> validate_inclusion(:status, @statuses)
    |> validate_path_lists()
    |> unique_constraint(:github_delivery_id)
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
