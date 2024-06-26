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

  @translatable_type :case_study

  schema "case_studies" do
    field :title, :string
    field :url, :string
    field :company, :string
    field :role, :string
    field :timeline, :string
    field :read_time, :integer
    field :platforms, {:array, :string}
    field :introduction, :string
    field :content, :string
    field :sort_order, :integer
    field :file_path, :string
    field :locale, :string

    has_many :translations, Portfolio.Translation, foreign_key: :translatable_id

    timestamps()
  end

  @doc false
  def changeset(case_study, attrs) do
    case_study
    |> cast(attrs, [
      :title,
      :url,
      :company,
      :role,
      :timeline,
      :read_time,
      :platforms,
      :introduction,
      :content,
      :sort_order,
      :file_path,
      :locale
    ])
    |> validate_required([
      :title,
      :url,
      :company,
      :role,
      :timeline,
      :read_time,
      :platforms,
      :introduction,
      :sort_order,
      :file_path,
      :locale
    ])
    |> unique_constraint(:url)
  end

  def translatable_type, do: @translatable_type
  def translatable_type_string, do: Atom.to_string(@translatable_type)
end
