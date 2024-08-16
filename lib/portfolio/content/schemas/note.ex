defmodule Portfolio.Content.Schemas.Note do
  use Portfolio.Content.Schemas.BaseSchema,
    schema_name: "notes",
    translatable_type: "note"

  @moduledoc """
  Defines the schema and behavior for blog notes in the Portfolio application.

  This module provides a schema for storing blog notes, inheriting common
  functionality from BaseSchema. It includes features such as:

  - Validation of note attributes including title length
  - Ensuring URL uniqueness

  All fields and validations are inherited from BaseSchema.
  """

  @typedoc """
  The Note type.
  """
  @type t :: %__MODULE__{}

  def custom_render(content) do
    # Add any Note-specific rendering logic here
    content
  end
end
