defmodule Portfolio.Content.Schemas.CaseStudy do
  @moduledoc """
  Defines the schema and behavior for case studies in the Portfolio application.
  Extends BaseSchema with additional fields specific to case studies.
  """
  use Portfolio.Content.Schemas.BaseSchema,
    schema_name: "case_studies",
    translatable_type: "case_study",
    additional_fields: [:company, :role, :timeline, :platforms, :sort_order],
    do: [
      field(:company, :string),
      field(:role, :string),
      field(:timeline, :string),
      field(:platforms, {:array, :string}),
      field(:sort_order, :integer)
    ]

  @typedoc """
  The CaseStudy type.
  """
  @type t :: %__MODULE__{}

  def custom_render(content) do
    # Add any CaseStudy-specific rendering logic here
    content
  end

  def changeset(case_study, attrs) do
    case_study
    |> super(attrs)
    |> validate_required([:company, :role, :timeline, :platforms, :sort_order])
  end
end
