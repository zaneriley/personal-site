defmodule Portfolio.Content.TranslatableFields do
  @moduledoc """
  Defines and manages translatable fields for different content types.
  """

  @case_study_fields [:title, :company, :role, :timeline, :introduction, :content]

  def case_study, do: @case_study_fields

  def all do
    @case_study_fields
  end

  # This function is called at compile-time to ensure all atoms are created
  def __force_atom_creation__ do
    all()
    |> Enum.each(&(&1 |> Atom.to_string() |> String.to_atom()))
  end
end
