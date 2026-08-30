defmodule Portfolio.Content.Schemas.BaseSchema do
  @moduledoc """
  Provides a base schema for content types in the Portfolio application.
  Defines common fields, validations, and behaviors for content schemas.
  """

  import Ecto.Changeset

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
      @alias_slug_pattern ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/

      @markdown_fields unquote(opts[:markdown_fields] || ["content"])

      schema unquote(schema_name) do
        field :title, :string
        field :url, :string
        field :aliases, {:array, :string}, default: []
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
        # nil = use the type default for main-feed membership (feeds-spec.md)
        field :main_feed, :boolean

        has_many :translations, Translation, foreign_key: :translatable_id

        timestamps()

        unquote(opts[:do])
      end

      @required_fields [:title, :content, :locale]
      @optional_fields [
        :url,
        :aliases,
        :introduction,
        :share_title,
        :share_description,
        :share_image_direction,
        :share_image_alt,
        :read_time,
        :file_path,
        :published_at,
        :is_draft,
        :word_count,
        :stored_ast,
        :main_feed
      ]

      @spec changeset(struct(), map()) :: Ecto.Changeset.t()
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
          |> Portfolio.Content.Schemas.BaseSchema.normalize_aliases()
          |> Portfolio.Content.Schemas.BaseSchema.validate_aliases(
            @max_url_length,
            @alias_slug_pattern
          )
          |> unique_constraint(:url)
          |> unique_constraint(:url,
            name: unquote(publication_generation_url_index)
          )
          |> unique_constraint(:url, name: unquote(unpublished_url_index))
          |> foreign_key_constraint(:publication_generation_id)
          |> validate_content()

        changeset
      end

      @spec translatable_type() :: String.t()
      def translatable_type, do: unquote(to_string(opts[:translatable_type]))

      @spec markdown_fields() :: [String.t()]
      def markdown_fields, do: @markdown_fields

      # Callback for custom rendering in child schemas
      @spec custom_render(term()) :: term()
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

  @doc """
  Trims string aliases before validating them.
  """
  @spec normalize_aliases(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def normalize_aliases(changeset) do
    update_change(changeset, :aliases, fn aliases ->
      Enum.map(aliases, fn
        alias_url when is_binary(alias_url) -> String.trim(alias_url)
        alias_url -> alias_url
      end)
    end)
  end

  @doc """
  Validates author-facing legacy URL aliases.
  """
  @spec validate_aliases(Ecto.Changeset.t(), pos_integer(), Regex.t()) ::
          Ecto.Changeset.t()
  def validate_aliases(changeset, max_url_length, alias_slug_pattern) do
    aliases = get_field(changeset, :aliases) || []
    url = get_field(changeset, :url)

    changeset
    |> maybe_add_alias_error(
      Enum.any?(aliases, &(is_binary(&1) and &1 == "")),
      "cannot include blank URLs"
    )
    |> maybe_add_alias_error(
      is_binary(url) and url in aliases,
      "cannot include the canonical URL"
    )
    |> maybe_add_alias_error(
      Enum.uniq(aliases) != aliases,
      "cannot include duplicate URLs"
    )
    |> maybe_add_alias_error(
      Enum.any?(
        aliases,
        &(is_binary(&1) and String.length(&1) > max_url_length)
      ),
      "cannot include URLs longer than #{max_url_length} characters"
    )
    |> maybe_add_alias_error(
      Enum.any?(aliases, &invalid_alias_slug?(&1, alias_slug_pattern)),
      "must be old slugs using lowercase letters, numbers, and hyphens"
    )
  end

  defp maybe_add_alias_error(changeset, true, message) do
    add_error(changeset, :aliases, message)
  end

  defp maybe_add_alias_error(changeset, false, _message), do: changeset

  defp invalid_alias_slug?(alias_url, alias_slug_pattern)
       when is_binary(alias_url) do
    not Regex.match?(alias_slug_pattern, alias_url)
  end

  defp invalid_alias_slug?(_alias_url, _alias_slug_pattern), do: true
end
