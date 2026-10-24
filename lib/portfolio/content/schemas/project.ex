defmodule Portfolio.Content.Schemas.Project do
  @moduledoc """
  Defines the schema and behavior for projects in the Portfolio application.
  Extends BaseSchema with additional fields specific to projects.
  """
  require Logger

  use Portfolio.Content.Schemas.BaseSchema,
    schema_name: "projects",
    translatable_type: "project",
    additional_fields: [:company, :role, :timeline, :platforms, :sort_order],
    do: [
      field(:company, :string),
      field(:role, :string),
      field(:timeline, :string),
      field(:platforms, {:array, :string}),
      field(:sort_order, :integer)
    ]

  @typedoc """
  The Project type.
  """
  @type t :: %__MODULE__{}

  def custom_render(content) do
    # Add any Project-specific rendering logic here
    content
  end

  def changeset(project, attrs) do
    project
    |> super(attrs)
    |> validate_required([:company, :role, :timeline, :platforms, :sort_order])
  end
end
