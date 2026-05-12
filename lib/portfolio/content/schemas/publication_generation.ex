defmodule Portfolio.Content.Schemas.PublicationGeneration do
  @moduledoc """
  A prepared content generation that can become the live publication view.

  Generations are the double buffer for content publishing: content rows are
  written against a generation before the publication state points visitors at
  that generation.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]
  @sources ~w(publish rollback bootstrap)
  @statuses ~w(preparing live superseded failed)

  @type t :: %__MODULE__{}

  schema "content_publication_generations" do
    field :content_sha, :string
    field :source, :string, default: "publish"
    field :status, :string, default: "preparing"

    timestamps()
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(generation, attrs) do
    generation
    |> cast(attrs, [:content_sha, :source, :status])
    |> validate_required([:content_sha, :source, :status])
    |> validate_format(:content_sha, ~r/\A[0-9a-f]{40}\z/i)
    |> validate_inclusion(:source, @sources)
    |> validate_inclusion(:status, @statuses)
    |> check_constraint(:content_sha, name: :content_sha_format)
    |> check_constraint(:source, name: :content_generation_source)
    |> check_constraint(:status, name: :content_generation_status)
  end
end
