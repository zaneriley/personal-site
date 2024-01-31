defmodule Portfolio.Translation do
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
