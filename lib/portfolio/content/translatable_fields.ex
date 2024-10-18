defmodule Portfolio.Content.TranslatableFields do
  @moduledoc """
  Provides functionality to determine translatable fields for content schemas.

  This module serves as a centralized configuration for managing which fields
  should be translated for each content type in the Portfolio application.
  """

  alias Portfolio.Content.Schemas.{CaseStudy, Note}

  @type schema :: module()
  @type field :: atom()

  @default_translatable_types [:string, :text, :integer]

  @doc """
  Returns a list of translatable fields for a given schema.

  This function determines which fields of a schema should be considered for
  translation. It applies a default rule (all string and text fields are
  translatable) and then applies any schema-specific rules.

  ## Parameters

    * `schema` - The module representing the Ecto schema

  ## Returns

  A list of atom field names that are considered translatable for the given schema.

  ## Examples

      iex> TranslatableFields.translatable_fields(Portfolio.Content.Schemas.CaseStudy)
      [:title, :content, :introduction, :company, :role, :timeline, :platforms]

      iex> TranslatableFields.translatable_fields(Portfolio.Content.Schemas.Note)
      [:title, :content, :introduction]
  """
  @spec translatable_fields(schema()) :: [field()]
  def translatable_fields(schema) do
    all_fields = schema.__schema__(:fields)
    default_translatable = default_translatable_fields(schema)

    case schema do
      CaseStudy -> default_translatable -- ([:url] ++ [:platforms])
      Note -> default_translatable
      _ -> default_translatable
    end
  end

  @doc """
  Determines if a specific field in a schema is translatable.

  ## Parameters

    * `schema` - The module representing the Ecto schema
    * `field` - The atom name of the field to check

  ## Returns

  Boolean indicating whether the field is translatable.

  ## Examples

      iex> TranslatableFields.translatable_field?(Portfolio.Content.Schemas.CaseStudy, :title)
      true

      iex> TranslatableFields.translatable_field?(Portfolio.Content.Schemas.CaseStudy, :read_time)
      false
  """
  @spec translatable_field?(schema(), field()) :: boolean()
  def translatable_field?(schema, field) do
    field in translatable_fields(schema)
  end

  @spec default_translatable_fields(schema()) :: [field()]
  defp default_translatable_fields(schema) do
    schema.__schema__(:fields)
    |> Enum.filter(fn field ->
      schema.__schema__(:type, field) in @default_translatable_types
    end)
  end
end
