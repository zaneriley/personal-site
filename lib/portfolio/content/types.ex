defmodule Portfolio.Content.Types do
  @moduledoc """
  Provides utilities for managing content types in the Portfolio application.

  This module serves as the single source of truth for content types,
  their associated paths, and schema mappings.
  """
  require Logger

  @typedoc "Represents the content type as a string"
  @type content_type :: String.t()

  @typedoc "Represents a file path as a string"
  @type file_path :: String.t()

  def content_base_path do
    Application.get_env(:portfolio, :content_base_path, "priv/content")
  end

  def content_types do
    %{
      "note" => %{
        slugs: ["notes", "note"],
        path: Path.join(content_base_path(), "note")
      },
      "case_study" => %{
        slugs: ["case-studies", "case_study", "case-study"],
        path: Path.join(content_base_path(), "case-study")
      }
    }
  end

  @spec get_supported_locales() :: [String.t()]
  def get_supported_locales do
    Application.get_env(:portfolio, :supported_locales, ["en"])
  end

  @doc """
  Returns the file path for a given content type and locale.

  ## Parameters

    * `content_type` - The content type
    * `locale` - The locale (default: Application.get_env(:portfolio, :default_locale, "en"))

  ## Returns

    * The file path as a string if found, otherwise `nil`

  ## Examples

      iex> Portfolio.Content.Types.get_path("note", "en")
      "priv/content/note/en"

      iex> Portfolio.Content.Types.get_path("invalid", "en")
      nil

  """
  @spec get_path(content_type()) :: file_path() | nil
  def get_path(content_type) do
    case content_types()[content_type] do
      nil -> nil
      %{path: path} -> path
    end
  end

  @doc """
  Determines the content type based on the given file path.

  ## Parameters

    * `file_path` - The path of the file to check

  ## Returns

    * The content type as a string if found, otherwise `nil`

  ## Examples

      iex> Portfolio.Content.Types.get_type("/path/to/priv/content/note/en/example.md")
      "note"

      iex> Portfolio.Content.Types.get_type("/path/to/unknown/example.md")
      nil

  """
  @spec get_type(file_path()) ::
          {:ok, content_type()} | {:error, :unknown_content_type}
  def get_type(file_path) do
    path_components = Path.split(file_path)
    slug_map = build_slug_map()

    result =
      Enum.find_value(path_components, fn component ->
        slug_map[component]
      end)

    case result do
      nil ->
        Logger.warning("Unrecognized content type for path: #{file_path}")
        {:error, :unknown_content_type}

      type ->
        Logger.debug("Successfully determined content type: #{type}")
        {:ok, type}
    end
  end

  defp build_slug_map do
    Enum.reduce(content_types(), %{}, fn {type, %{slugs: slugs}}, acc ->
      Enum.reduce(slugs, acc, fn slug, inner_acc ->
        Map.put(inner_acc, slug, type)
      end)
    end)
  end

  defp normalize_path(file_path) do
    app_root =
      Application.get_env(:portfolio, :content_root_path, "priv/content")

    String.replace(file_path, ~r(^.*?#{app_root}), app_root)
  end

  @doc """
  Returns a list of all defined content types.

  ## Returns

    * A list of content types as strings

  ## Examples

      iex> Portfolio.Content.Types.all_types()
      ["note", "case_study"]

  """
  @spec all_types() :: [content_type()]
  def all_types, do: Map.keys(content_types())

  @doc """
  Checks if the given type is a valid content type.

  ## Parameters

    * `type` - The type to check

  ## Returns

    * `true` if the type is valid, `false` otherwise

  ## Examples

      iex> Portfolio.Content.Types.valid_type?("note")
      true

      iex> Portfolio.Content.Types.valid_type?("invalid")
      false

  """
  @spec valid_type?(content_type()) :: boolean()
  def valid_type?(type), do: type in all_types()

  @doc """
  Returns the schema module associated with the given content type.

  ## Parameters

    * `type` - The content type

  ## Returns

    * The schema module if found, otherwise `{:error, :invalid_content_type}`

  ## Examples

      iex> Portfolio.Content.Types.get_schema("note")
      Portfolio.Content.Schemas.Note

      iex> Portfolio.Content.Types.get_schema("invalid")
      {:error, :invalid_content_type}

  """
  @spec get_schema(content_type() | atom()) ::
          module() | {:error, :invalid_content_type}
  def get_schema(type) when is_atom(type), do: get_schema(Atom.to_string(type))

  def get_schema(type) when is_binary(type) do
    Logger.debug("Getting schema for type: #{inspect(type)}")

    case type do
      "note" ->
        Logger.debug(
          "Found note schema, returning: #{inspect(Portfolio.Content.Schemas.Note)}"
        )

        Portfolio.Content.Schemas.Note

      "case_study" ->
        Logger.debug(
          "Found case study schema, returning: #{inspect(Portfolio.Content.Schemas.CaseStudy)}"
        )

        Portfolio.Content.Schemas.CaseStudy

      _ ->
        Logger.error("No schema found for type: #{inspect(type)}")
        {:error, :invalid_content_type}
    end
  end
end
