defmodule Portfolio.CaseStudy do
  use Ecto.Schema
  import Ecto.Changeset

  schema "case_studies" do
    field :title, :string
    field :url, :string
    field :role, :string
    field :timeline, :string
    field :read_time, :integer
    field :platforms, {:array, :string}
    field :introduction, :string

    timestamps()
  end

  @doc false
  def changeset(case_study, attrs) do
    case_study
    |> cast(attrs, [:title, :url, :role, :timeline, :read_time, :platforms, :introduction])
    |> validate_required([:title, :url, :role, :timeline, :read_time, :platforms, :introduction])
  end
end
