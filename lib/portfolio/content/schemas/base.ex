defmodule Portfolio.Content.Schemas.BaseSchema do
  @moduledoc """
  Provides a base schema for content types in the Portfolio application.
  Defines common fields, validations, and behaviors for content schemas.
  """
  require Logger

  defmacro __using__(opts) do
    schema_name = opts[:schema_name] || raise(":schema_name option is required")

    publication_generation_url_index =
      :"#{schema_name}_url_publication_generation_index"

    unpublished_url_index = :"#{schema_name}_url_unpublished_index"

    quote do
      use Ecto.Schema
      import Ecto.Changeset
      alias Portfolio.Content.Schemas.Translation
      alias Portfolio.Content.Markdown.Renderer
      alias Portfolio.Cache

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime]
      @max_url_length 255
      @max_title_length unquote(opts[:max_title_length] || 255)

      @markdown_fields unquote(opts[:markdown_fields] || ["content"])

      schema unquote(schema_name) do
        field :title, :string
        field :url, :string
        # raw markdown
        field :content, :string
        # compiled html
        field :compiled_content, :string, virtual: true
        # stored AST representation
        field :stored_ast, {:array, :map}
        field :introduction, :string
        field :share_title, :string
        field :share_description, :string
        field :share_image_direction, :string
        field :share_image_alt, :string
        field :read_time, :integer
        field :word_count, :integer
        field :file_path, :string
        field :publication_generation_id, :binary_id
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
        :share_title,
        :share_description,
        :share_image_direction,
        :share_image_alt,
        :read_time,
        :file_path,
        :publication_generation_id,
        :published_at,
        :is_draft,
        :word_count,
        :stored_ast
      ]

      def changeset(struct, attrs) do
        changeset =
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
          |> unique_constraint(:url,
            name: unquote(publication_generation_url_index)
          )
          |> unique_constraint(:url, name: unquote(unpublished_url_index))
          |> validate_content()

        changeset
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
