defmodule Portfolio.CaseStudy do
  @moduledoc """
  Represents the case study content within the application, providing a schema and validation for case study records.

  The CaseStudy schema includes:
  - Descriptive fields such as title, URL, role, timeline, and introduction.
  - Numeric fields like read time.
  - An array of platforms to indicate where the case study is applicable.
  - Associations to translations, allowing each case study to be available in multiple languages.

  The `changeset/2` function is responsible for casting and validating the input data when creating or updating case studies
  """
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

    has_many :translations, Portfolio.Translation,
      foreign_key: :translatable_id,
      where: [translatable_type: "CaseStudy"]

    timestamps()
  end

  @doc false
  def changeset(case_study, attrs) do
    case_study
    |> cast(attrs, [
      :title,
      :url,
      :role,
      :timeline,
      :read_time,
      :platforms,
      :introduction
    ])
    |> validate_required([
      :title,
      :url,
      :role,
      :timeline,
      :read_time,
      :platforms,
      :introduction
    ])
    |> unique_constraint(:url)
  end
end
