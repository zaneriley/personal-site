defmodule Portfolio.Translation do
  @moduledoc """
  Manages translations for various translatable entities within the application.

  The Translation schema is designed to store localized text for different fields associated with translatable entities. Each translation record includes:
  - The `locale` indicating the language and regional preferences.
  - The `field_name` specifying which field of the entity is translated.
  - The `field_value` containing the actual translated text.
  - The `translatable_id` and `translatable_type` identifying the entity that the translation belongs to.

  This setup allows the application to support multiple languages by fetching the appropriate translations based on the user's selected locale.
  """
  use Ecto.Schema

  schema "translations" do
    field :locale, :string
    field :field_name, :string
    field :field_value, :string
    field :translatable_id, :integer
    field :translatable_type, :string

    timestamps()
  end
end
