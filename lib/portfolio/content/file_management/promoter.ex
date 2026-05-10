defmodule Portfolio.Content.FileManagement.Promoter do
  @moduledoc """
  Promotes content files from the checked-out content repository into the DB.

  Promotion is the boundary between "git has new files" and "the site can serve
  the content." It parses Markdown frontmatter, upserts renderable content, and
  removes entries whose source Markdown disappeared.

  Validator and local promotion callers use rollback-on-error so a failed
  promotion leaves no residue. The remote publication path keeps failed
  generation rows for diagnosis, but the publication state does not move the
  live pointer to that generation.
  """

  import Ecto.Query

  alias Portfolio.Content
  alias Portfolio.Content.FileManagement.Reader
  alias Portfolio.Content.Schemas.CaseStudy
  alias Portfolio.Content.Schemas.Note
  alias Portfolio.Content.Types
  alias Portfolio.Repo

  @type change_set :: %{
          optional(:upsert) => [String.t()],
          optional(:delete) => [String.t()]
        }

  @type promotion_error :: %{path: String.t(), reason: term()}

  @type promotion_result :: %{
          promoted: [String.t()],
          removed: [String.t()],
          skipped: [String.t()],
          errors: [promotion_error()]
        }

  @content_schemas [Note, CaseStudy]

  @doc """
  Promotes every Markdown file under the content base path and prunes missing
  content entries that previously came from that tree.
  """
  @spec promote_all(String.t(), keyword()) ::
          {:ok, promotion_result()} | {:error, promotion_result()}
  def promote_all(content_base_path, opts \\ [])
      when is_binary(content_base_path) do
    content_base_path = Path.expand(content_base_path)
    publication_generation_id = Keyword.get(opts, :publication_generation_id)

    with {:ok, files} <- list_markdown_files(content_base_path) do
      promote_all_files(
        content_base_path,
        files,
        publication_generation_id,
        opts
      )
    end
  end

  @doc """
  Promotes the changed paths from a webhook payload.

  Added/modified files are parsed and upserted. Removed files are unpublished
  from the DB by source path. The whole set is transactional.
  """
  @spec promote_changes(String.t(), change_set(), keyword()) ::
          {:ok, promotion_result()} | {:error, promotion_result()}
  def promote_changes(content_base_path, changes, opts \\ [])
      when is_binary(content_base_path) do
    content_base_path = Path.expand(content_base_path)
    publication_generation_id = Keyword.get(opts, :publication_generation_id)

    promote_in_transaction(opts, fn ->
      result =
        changes
        |> Map.get(:upsert, [])
        |> reduce_changed_paths(
          content_base_path,
          new_result(),
          fn path, result ->
            promote_path_change(path, result, publication_generation_id)
          end
        )

      changes
      |> Map.get(:delete, [])
      |> reduce_changed_paths(content_base_path, result, fn path, result ->
        remove_path_change(path, result, publication_generation_id)
      end)
      |> validate_alias_integrity(publication_generation_id)
      |> validate_deleted_aliases(
        content_base_path,
        changes,
        publication_generation_id
      )
    end)
  end

  @doc """
  Promotes or removes a single file path, used by the filesystem watcher.
  """
  @spec promote_path(String.t(), keyword()) ::
          {:ok, promotion_result()} | {:error, promotion_result()}
  def promote_path(path, opts \\ []) when is_binary(path) do
    publication_generation_id = Keyword.get(opts, :publication_generation_id)

    promote_in_transaction(opts, fn ->
      path
      |> Path.expand()
      |> promote_path_change(new_result(), publication_generation_id)
      |> validate_alias_integrity(publication_generation_id)
    end)
  end

  defp promote_in_transaction(opts, fun) do
    rollback_on_error? = Keyword.get(opts, :rollback_on_error, true)

    fun
    |> transaction(rollback_on_error?)
    |> normalize_transaction_result(rollback_on_error?)
  end

  defp transaction(fun, rollback_on_error?) do
    Repo.transaction(fn ->
      result = fun.()

      if rollback_on_error? do
        rollback_on_errors(result)
      else
        result
      end
    end)
  end

  defp rollback_on_errors(%{errors: []} = result), do: result
  defp rollback_on_errors(result), do: Repo.rollback(result)

  defp normalize_transaction_result(transaction_result, rollback_on_error?) do
    case transaction_result do
      {:ok, %{errors: [_ | _]} = result} when not rollback_on_error? ->
        {:error, result}

      {:ok, result} ->
        {:ok, result}

      {:error, result} when is_map(result) ->
        {:error, result}

      {:error, reason} ->
        {:error, add_error(new_result(), "transaction", reason)}
    end
  end

  defp new_result do
    %{promoted: [], removed: [], skipped: [], errors: []}
  end

  defp promote_all_files(
         content_base_path,
         files,
         publication_generation_id,
         opts
       ) do
    promote_in_transaction(opts, fn ->
      files
      |> Enum.reduce(new_result(), fn path, result ->
        promote_existing_file(path, result, publication_generation_id)
      end)
      |> remove_missing_content(
        content_base_path,
        files,
        publication_generation_id
      )
      |> validate_alias_integrity(publication_generation_id)
      |> validate_deleted_aliases(
        content_base_path,
        Keyword.get(opts, :changes, %{upsert: [], delete: []}),
        publication_generation_id
      )
    end)
  end

  defp reduce_changed_paths(paths, content_base_path, result, reducer) do
    Enum.reduce(paths, result, fn raw_path, acc ->
      path = content_path(content_base_path, raw_path)

      if under_base_path?(path, content_base_path) do
        reducer.(path, acc)
      else
        add_error(acc, path, :path_outside_content_base)
      end
    end)
  end

  defp list_markdown_files(content_base_path) do
    if File.dir?(content_base_path) do
      files =
        content_base_path
        |> Path.join("**/*.md")
        |> Path.wildcard()
        |> Enum.map(&Path.expand/1)
        |> Enum.reject(&hidden_path?/1)
        |> Enum.filter(&publishable_markdown_path?/1)
        |> Enum.sort()

      {:ok, files}
    else
      {:error,
       add_error(new_result(), content_base_path, :missing_content_base_path)}
    end
  end

  defp promote_path_change(path, result, publication_generation_id) do
    cond do
      hidden_path?(path) ->
        skip_path(result, path)

      Path.extname(path) != ".md" ->
        skip_path(result, path)

      File.exists?(path) ->
        promote_existing_file(path, result, publication_generation_id)

      true ->
        remove_path_change(path, result)
    end
  end

  defp promote_existing_file(path, result, publication_generation_id) do
    case Reader.read_markdown_file(path) do
      {:ok, content_type, attrs} ->
        attrs =
          maybe_put_publication_generation_id(attrs, publication_generation_id)

        upsert_file(content_type, attrs, path, result)

      {:error, reason} ->
        add_error(result, path, reason)
    end
  end

  defp upsert_file(content_type, attrs, path, result) do
    case Content.upsert_from_file(content_type, attrs) do
      {:ok, _content} ->
        %{result | promoted: [path | result.promoted]}

      {:error, reason} ->
        add_error(result, path, reason)
    end
  end

  defp remove_path_change(path, result, publication_generation_id \\ nil)

  defp remove_path_change(path, result, publication_generation_id)
       when is_binary(publication_generation_id) do
    %{result | removed: [path | result.removed]}
  end

  defp remove_path_change(path, result, _publication_generation_id) do
    case delete_by_file_path(path) do
      {:ok, 0} ->
        %{result | skipped: [path | result.skipped]}

      {:ok, count} ->
        %{result | removed: List.duplicate(path, count) ++ result.removed}

      {:error, reason} ->
        add_error(result, path, reason)
    end
  end

  defp remove_missing_content(
         result,
         _content_base_path,
         _current_files,
         generation_id
       )
       when is_binary(generation_id) do
    result
  end

  defp remove_missing_content(
         result,
         content_base_path,
         current_files,
         _generation_id
       ) do
    current_paths = MapSet.new(Enum.map(current_files, &Path.expand/1))

    @content_schemas
    |> Enum.flat_map(&content_from_base_path(&1, content_base_path))
    |> Enum.reject(&(Path.expand(&1.file_path) in current_paths))
    |> Enum.reduce(result, fn content, acc ->
      case Content.delete(content.__struct__.translatable_type(), content) do
        {:ok, deleted_content} ->
          %{acc | removed: [deleted_content.file_path | acc.removed]}

        {:error, reason} ->
          add_error(acc, content.file_path, reason)
      end
    end)
  end

  defp content_from_base_path(schema, content_base_path) do
    schema
    |> where([content], not is_nil(content.file_path))
    |> Repo.all()
    |> Enum.filter(&under_base_path?(&1.file_path, content_base_path))
  end

  defp delete_by_file_path(path) do
    delete_paths = path_variants(path)

    result =
      Enum.reduce_while(@content_schemas, {:ok, 0}, fn schema, {:ok, count} ->
        contents =
          schema
          |> where([content], content.file_path in ^delete_paths)
          |> Repo.all()

        case delete_contents(contents) do
          {:ok, deleted_count} -> {:cont, {:ok, count + deleted_count}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)

    result
  end

  defp delete_contents(contents) do
    Enum.reduce_while(contents, {:ok, 0}, fn content, {:ok, count} ->
      case Content.delete(content.__struct__.translatable_type(), content) do
        {:ok, _content} -> {:cont, {:ok, count + 1}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp path_variants(path) do
    expanded_path = Path.expand(path)
    relative_path = Path.relative_to_cwd(expanded_path)

    [path, expanded_path, relative_path]
    |> Enum.uniq()
  end

  defp content_path(content_base_path, path) do
    path =
      path
      |> String.trim_leading("/")
      |> String.replace_prefix("priv/content/", "")

    Path.expand(path, content_base_path)
  end

  defp under_base_path?(path, content_base_path) do
    expanded_path = Path.expand(path)
    expanded_base_path = Path.expand(content_base_path)

    expanded_path == expanded_base_path or
      String.starts_with?(expanded_path, expanded_base_path <> "/")
  end

  defp hidden_path?(path) do
    path
    |> Path.split()
    |> Enum.any?(&String.starts_with?(&1, "."))
  end

  defp publishable_markdown_path?(path) do
    content_slugs =
      Types.content_types()
      |> Map.values()
      |> Enum.flat_map(& &1.slugs)

    path
    |> Path.split()
    |> Enum.any?(&(&1 in content_slugs))
  end

  defp skip_path(result, path), do: %{result | skipped: [path | result.skipped]}

  defp add_error(result, path, reason) do
    %{result | errors: [%{path: path, reason: reason} | result.errors]}
  end

  defp validate_alias_integrity(
         %{errors: [_first | _rest]} = result,
         _generation_id
       ) do
    result
  end

  defp validate_alias_integrity(result, generation_id) do
    alias_errors =
      @content_schemas
      |> Enum.flat_map(&alias_errors_for_schema(&1, generation_id))

    %{result | errors: alias_errors ++ result.errors}
  end

  defp alias_errors_for_schema(schema, generation_id) do
    contents = generation_contents(schema, generation_id)
    canonical_urls = MapSet.new(Enum.map(contents, & &1.url))

    canonical_alias_errors(contents, canonical_urls) ++
      duplicate_alias_errors(contents)
  end

  defp generation_contents(schema, nil) do
    schema
    |> where([content], is_nil(content.publication_generation_id))
    |> public_content()
    |> Repo.all()
  end

  defp generation_contents(schema, generation_id)
       when is_binary(generation_id) do
    schema
    |> where([content], content.publication_generation_id == ^generation_id)
    |> public_content()
    |> Repo.all()
  end

  defp public_content(query) do
    query
    |> where([content], not content.is_draft)
    |> where([content], not is_nil(content.published_at))
  end

  defp canonical_alias_errors(contents, canonical_urls) do
    Enum.flat_map(contents, fn content ->
      content
      |> aliases()
      |> Enum.filter(&MapSet.member?(canonical_urls, &1))
      |> Enum.map(&alias_error(content, {:alias_conflicts_with_url, &1}))
    end)
  end

  defp duplicate_alias_errors(contents) do
    contents
    |> Enum.flat_map(fn content ->
      Enum.map(aliases(content), &{&1, content})
    end)
    |> Enum.group_by(fn {alias_url, _content} -> alias_url end, fn {_alias_url,
                                                                    content} ->
      content
    end)
    |> Enum.flat_map(fn
      {_alias_url, [_content]} ->
        []

      {alias_url, duplicate_contents} ->
        Enum.map(
          duplicate_contents,
          &alias_error(&1, {:duplicate_alias, alias_url})
        )
    end)
  end

  defp aliases(%{aliases: aliases}) when is_list(aliases), do: aliases
  defp aliases(%{aliases: nil}), do: []

  defp alias_error(content, reason) do
    %{path: content_error_path(content), reason: reason}
  end

  defp validate_deleted_aliases(
         %{errors: [_first | _rest]} = result,
         _content_base_path,
         _changes,
         _generation_id
       ) do
    result
  end

  defp validate_deleted_aliases(
         result,
         _content_base_path,
         %{upsert: []},
         _generation_id
       ) do
    result
  end

  defp validate_deleted_aliases(
         result,
         _content_base_path,
         %{delete: []},
         _generation_id
       ) do
    result
  end

  defp validate_deleted_aliases(
         result,
         content_base_path,
         changes,
         generation_id
       )
       when is_binary(generation_id) do
    errors =
      changes
      |> Map.get(:delete, [])
      |> Enum.map(&content_path(content_base_path, &1))
      |> Enum.flat_map(&live_content_from_deleted_path/1)
      |> Enum.reject(&content_slug_preserved?(&1, generation_id))
      |> Enum.map(&alias_error(&1, {:deleted_without_alias, &1.url}))

    %{result | errors: errors ++ result.errors}
  end

  defp validate_deleted_aliases(
         result,
         _content_base_path,
         _changes,
         _generation_id
       ) do
    result
  end

  defp live_content_from_deleted_path(path) do
    case Portfolio.Content.Publishing.live_generation_id() do
      nil ->
        []

      live_generation_id ->
        delete_paths = path_variants(path)

        Enum.flat_map(@content_schemas, fn schema ->
          schema
          |> where(
            [content],
            content.publication_generation_id == ^live_generation_id
          )
          |> where([content], content.file_path in ^delete_paths)
          |> public_content()
          |> Repo.all()
        end)
    end
  end

  defp content_slug_preserved?(content, generation_id) do
    content.url in generation_slugs(content.__struct__, generation_id)
  end

  defp generation_slugs(schema, generation_id) do
    schema
    |> where([content], content.publication_generation_id == ^generation_id)
    |> public_content()
    |> Repo.all()
    |> Enum.flat_map(fn content -> [content.url | aliases(content)] end)
    |> MapSet.new()
  end

  defp content_error_path(%{file_path: file_path}) when is_binary(file_path) do
    file_path
  end

  defp content_error_path(%{url: url}) when is_binary(url) do
    url
  end

  defp maybe_put_publication_generation_id(attrs, nil) do
    scrub_publication_generation_id(attrs)
  end

  defp maybe_put_publication_generation_id(attrs, publication_generation_id) do
    attrs
    |> scrub_publication_generation_id()
    |> Map.put(:trusted_publication_generation_id, publication_generation_id)
  end

  defp scrub_publication_generation_id(attrs) do
    attrs
    |> Map.delete("publication_generation_id")
    |> Map.delete(:publication_generation_id)
    |> Map.delete(:trusted_publication_generation_id)
  end
end
