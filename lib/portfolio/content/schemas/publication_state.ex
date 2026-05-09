defmodule Portfolio.Content.Schemas.PublicationState do
  @moduledoc """
  Singleton read model for the current content publication state.

  This is the fast answer for "what content is live?" and "what was the last
  good content?" The append-only ledger remains the audit trail.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Portfolio.Content.Schemas.PublicationGeneration

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]
  @sync_states ~w(idle running failed)
  @sha_fields [
    :live_content_sha,
    :last_good_content_sha,
    :last_accepted_content_sha,
    :last_rejected_content_sha,
    :last_ignored_content_sha
  ]

  @type t :: %__MODULE__{}

  schema "content_publication_states" do
    field :name, :string, default: "default"
    field :live_content_sha, :string
    field :last_good_content_sha, :string
    field :last_accepted_content_sha, :string
    field :last_rejected_content_sha, :string
    field :last_rejected_reason, :string
    field :last_ignored_content_sha, :string
    field :last_ignored_reason, :string
    field :last_delivery_id, :string
    field :current_sync_state, :string, default: "idle"
    field :last_failure_reason, :string

    belongs_to :live_generation, PublicationGeneration,
      foreign_key: :live_content_publication_generation_id

    belongs_to :last_good_generation, PublicationGeneration,
      foreign_key: :last_good_content_publication_generation_id

    timestamps()
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(state, attrs) do
    state
    |> cast(attrs, [
      :name,
      :live_content_sha,
      :last_good_content_sha,
      :last_accepted_content_sha,
      :last_rejected_content_sha,
      :last_rejected_reason,
      :last_ignored_content_sha,
      :last_ignored_reason,
      :last_delivery_id,
      :current_sync_state,
      :last_failure_reason,
      :live_content_publication_generation_id,
      :last_good_content_publication_generation_id
    ])
    |> validate_required([:name, :current_sync_state])
    |> validate_inclusion(:current_sync_state, @sync_states)
    |> validate_sha_fields()
    |> check_constraint(:name, name: :singleton_state_name)
    |> check_constraint(:current_sync_state, name: :content_sync_state)
    |> check_constraint(:live_content_sha, name: :live_content_sha_format)
    |> check_constraint(:last_good_content_sha,
      name: :last_good_content_sha_format
    )
    |> check_constraint(:last_accepted_content_sha,
      name: :last_accepted_content_sha_format
    )
    |> check_constraint(:last_rejected_content_sha,
      name: :last_rejected_content_sha_format
    )
    |> check_constraint(:last_ignored_content_sha,
      name: :last_ignored_content_sha_format
    )
    |> foreign_key_constraint(:live_content_publication_generation_id)
    |> foreign_key_constraint(:last_good_content_publication_generation_id)
    |> unique_constraint(:name)
  end

  defp validate_sha_fields(changeset) do
    Enum.reduce(@sha_fields, changeset, fn field, acc ->
      validate_change(acc, field, &sha_format_error/2)
    end)
  end

  defp sha_format_error(_field, nil), do: []

  defp sha_format_error(field, value) do
    if valid_sha?(value) do
      []
    else
      [{field, "has invalid format"}]
    end
  end

  defp valid_sha?(value) when is_binary(value),
    do: String.match?(value, ~r/\A[0-9a-f]{40}\z/i)

  defp valid_sha?(_value), do: false
end
