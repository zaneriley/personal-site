defmodule Portfolio.Content.FileManagement.ValidationError do
  @moduledoc """
  Converts content validation failure terms into author-facing messages.
  """

  alias Ecto.Changeset

  @doc """
  Returns one or more stable messages for a validation failure reason.
  """
  @spec messages(term()) :: [String.t()]
  def messages(%Changeset{} = changeset) do
    changeset
    |> changeset_errors()
    |> case do
      [] -> ["schema validation failed"]
      errors -> errors
    end
  end

  def messages({:yaml_parsing_failed, _reason}) do
    ["frontmatter: invalid YAML"]
  end

  def messages(:invalid_markdown_format) do
    ["invalid markdown format: expected YAML frontmatter delimited by ---"]
  end

  def messages(:nil_url) do
    ["url: is required"]
  end

  def messages(:unencrypted_draft) do
    ["unencrypted draft: is_draft true files must be encrypted before push"]
  end

  def messages({:alias_conflicts_with_url, alias_url})
      when is_binary(alias_url) do
    ["aliases: #{alias_url} conflicts with a canonical URL"]
  end

  def messages({:duplicate_alias, alias_url})
      when is_binary(alias_url) do
    ["aliases: #{alias_url} is used by more than one content file"]
  end

  def messages({:deleted_without_alias, slug}) when is_binary(slug) do
    [
      "deleted URL #{slug} needs an alias on new content or a deletion-only commit"
    ]
  end

  def messages(reason) when is_atom(reason) do
    [reason |> Atom.to_string() |> String.replace("_", " ")]
  end

  def messages(%module{} = reason) when is_exception(reason) do
    ["#{inspect(module)}: #{Exception.message(reason)}"]
  end

  def messages(reason) do
    [inspect(reason)]
  end

  @doc """
  Returns a single-line message for status/debug surfaces.
  """
  @spec message(term()) :: String.t()
  def message(reason) do
    reason
    |> messages()
    |> Enum.join("; ")
  end

  defp changeset_errors(%Changeset{} = changeset) do
    Enum.map(changeset.errors, fn {field, {message, opts}} ->
      "#{field}: #{interpolate_message(message, opts)}"
    end)
  end

  defp interpolate_message(message, opts) do
    Regex.replace(~r"%{(\w+)}", message, fn _, key ->
      opts
      |> option_value(key)
      |> to_string()
    end)
  end

  defp option_value(opts, key) do
    Enum.find_value(opts, key, fn {option_key, value} ->
      if Atom.to_string(option_key) == key do
        value
      end
    end)
  end
end
