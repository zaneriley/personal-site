defmodule Portfolio.Content.Schemas.BaseSchema do
  @moduledoc """
  Provides a base schema for content types in the Portfolio application.
  Defines common fields, validations, and behaviors for content schemas.
  """
  defmacro __using__(opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      alias Portfolio.Content.Schemas.Translation
      alias Portfolio.Content.MarkdownRendering.Renderer
      alias Portfolio.Cache

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime]
      @max_url_length 255
      @max_title_length unquote(opts[:max_title_length] || 255)

      @markdown_fields unquote(opts[:markdown_fields] || ["content"])

      schema unquote(
               opts[:schema_name] || raise(":schema_name option is required")
             ) do
        field :title, :string
        field :url, :string
        # raw markdown
        field :content, :string
        # compiled html
        field :compiled_content, :string, virtual: true
        field :introduction, :string
        field :read_time, :integer
        field :file_path, :string
        field :locale, :string
        field :published_at, :utc_datetime
        field :is_draft, :boolean, default: true

        has_many :translations, Translation, foreign_key: :translatable_id

        timestamps()

        unquote(opts[:do])
      end

      @required_fields [:title, :content, :locale]
      @optional_fields [
        :url,
        :introduction,
        :read_time,
        :file_path,
        :published_at,
        :is_draft
      ]

      def changeset(struct, attrs) do
        struct
        |> cast(
          attrs,
          @required_fields ++
            @optional_fields ++ unquote(opts[:additional_fields] || [])
        )
        |> validate_required(@required_fields)
        |> validate_length(:title, max: @max_title_length)
        |> validate_length(:url, max: @max_url_length)
        |> unique_constraint(:url)
        |> validate_content()
      end

      @spec translatable_type() :: String.t()
      def translatable_type, do: unquote(to_string(opts[:translatable_type]))

      def markdown_fields, do: @markdown_fields

      # Callback for custom rendering in child schemas
      def custom_render(_content), do: nil

      defoverridable changeset: 2, custom_render: 1

      defp validate_content(changeset) do
        case get_change(changeset, :content) do
          nil -> changeset
          content when is_binary(content) -> changeset
          _ -> add_error(changeset, :content, "must be a string")
        end
      end
    end
  end
end
