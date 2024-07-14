defmodule Portfolio.Content.TranslatableFields do
  @moduledoc """
  Defines and manages translatable fields for different content types.
  """

  @case_study_fields [
    :title,
    :company,
    :role,
    :timeline,
    :introduction,
    :content
  ]
  @additional_fields [:custom_field]

  # Force atom creation at compile-time
  @all_fields (@case_study_fields ++ @additional_fields) |> Enum.uniq()
  @all_field_strings @all_fields |> Enum.map(&Atom.to_string/1)

  def case_study, do: @case_study_fields
  def additional, do: @additional_fields

  def all, do: @all_fields

  def all_strings, do: @all_field_strings
end
