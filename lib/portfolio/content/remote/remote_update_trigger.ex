defmodule Portfolio.Content.Remote.RemoteUpdateTrigger do
  @moduledoc """
  Manages remote content updates and triggers file processing.

  This module is responsible for:
  - Syncing remote Git repositories
  - Handling updates for changed files
  - Processing individual files and updating the local content

  It uses `GitRepoSyncer` to check out remote content at the requested commit
  and `Promoter` to atomically publish changed files into the local database.
  """

  alias Portfolio.Content
  alias Portfolio.Content.FileManagement.Promoter
  alias Portfolio.Content.FileManagement.ValidationError
  alias Portfolio.Content.Publishing
  alias Portfolio.Content.Remote.GitRepoSyncer
  alias Portfolio.Content.Remote.GitHubStatusReporter
  alias Portfolio.Content.Schemas.PublicationLedgerEntry

  require Logger

  @doc """
  Triggers an update for a given repository URL.

  ## Parameters

    - repo_url: The URL of the Git repository to update.

  ## Returns

    - `{:ok, result}` if the sync and promotion were successful.
    - `{:error, reason}` if the sync or promotion failed.
  """
  @spec trigger_update(String.t(), keyword()) ::
          {:ok, Promoter.promotion_result()} | {:error, String.t()}
  def trigger_update(repo_url, opts \\ []) do
    perform_update(repo_url, opts)
  end

  defp perform_update(repo_url, opts) do
    local_path =
      Keyword.get(opts, :content_base_path) ||
        Application.get_env(:portfolio, :content_base_path, nil)

    target_sha = Keyword.get(opts, :target_sha)
    github_delivery_id = delivery_id_before_sync(target_sha, opts)

    result =
      Publishing.with_publication_lock(fn ->
        case duplicate_delivery_entry(github_delivery_id) do
          %PublicationLedgerEntry{} = entry ->
            Logger.info(
              "Duplicate content delivery ignored: #{github_delivery_id}"
            )

            {:ok, duplicate_result(), entry}

          nil ->
            mark_sync_running(github_delivery_id)

            sync_and_promote(
              repo_url,
              local_path,
              target_sha,
              github_delivery_id,
              opts
            )
        end
      end)

    report_publication_result(result, opts)
  end

  defp report_publication_result(
         {:ok, result, %PublicationLedgerEntry{} = entry},
         opts
       ) do
    GitHubStatusReporter.report_and_log(entry, opts)

    {:ok, result}
  end

  defp report_publication_result(
         {:error, reason, %PublicationLedgerEntry{} = entry},
         opts
       ) do
    GitHubStatusReporter.report_and_log(entry, opts)

    {:error, reason}
  end

  defp report_publication_result(result, _opts), do: result

  defp duplicate_delivery_entry(nil), do: nil

  defp duplicate_delivery_entry(github_delivery_id) do
    Publishing.get_ledger_entry_by_delivery_id(github_delivery_id)
  end

  defp sync_and_promote(
         repo_url,
         local_path,
         target_sha,
         github_delivery_id,
         opts
       ) do
    sync_opts =
      opts
      |> Keyword.take([:auth, :git_command])
      |> Keyword.put(:target_sha, target_sha)

    case GitRepoSyncer.sync_repo(repo_url, local_path, sync_opts) do
      {:ok, _} ->
        content_sha = target_sha || GitRepoSyncer.current_sha!(local_path)

        github_delivery_id =
          github_delivery_id || github_delivery_id(content_sha, opts)

        case duplicate_delivery_entry(github_delivery_id) do
          %PublicationLedgerEntry{} = entry ->
            Logger.info(
              "Duplicate content delivery ignored: #{github_delivery_id}"
            )

            {:ok, duplicate_result(), entry}

          nil ->
            mark_sync_running(github_delivery_id)

            promote_synced_content(
              local_path,
              content_sha,
              github_delivery_id,
              opts
            )
        end

      {:error, reason} ->
        github_delivery_id =
          github_delivery_id || sync_failure_delivery_id(opts)

        handle_sync_error(target_sha, github_delivery_id, reason, opts)
    end
  end

  defp promote_synced_content(local_path, content_sha, github_delivery_id, opts) do
    with {:ok, generation} <-
           Publishing.prepare_generation(content_sha,
             source: Keyword.get(opts, :source, :publish)
           ) do
      opts = Keyword.put(opts, :content_base_path, local_path)

      do_promote_synced_content(
        local_path,
        content_sha,
        github_delivery_id,
        generation,
        opts
      )
    end
  end

  defp do_promote_synced_content(
         local_path,
         content_sha,
         github_delivery_id,
         generation,
         opts
       ) do
    case Promoter.promote_all(local_path,
           publication_generation_id: generation.id,
           rollback_on_error: false,
           changes: Keyword.get(opts, :changes, %{upsert: [], delete: []})
         ) do
      {:ok, result} ->
        result = add_removed_paths_from_changes(result, local_path, opts)

        handle_promotion_success(
          content_sha,
          github_delivery_id,
          generation,
          result,
          opts
        )

      {:error, result} ->
        result = add_removed_paths_from_changes(result, local_path, opts)

        handle_promotion_error(
          content_sha,
          github_delivery_id,
          generation,
          result,
          opts
        )
    end
  end

  defp handle_promotion_success(
         content_sha,
         github_delivery_id,
         generation,
         result,
         opts
       ) do
    case record_accepted_verdict(
           content_sha,
           github_delivery_id,
           generation,
           result,
           opts
         ) do
      {:ok, entry} ->
        Logger.info("Content promotion completed: #{inspect(result)}")
        {:ok, result, entry}

      {:error, changeset} ->
        Logger.error(
          "Failed to record accepted content verdict: #{inspect(changeset)}"
        )

        {:error, "Publication verdict recording failed"}
    end
  end

  defp handle_promotion_error(
         content_sha,
         github_delivery_id,
         generation,
         result,
         opts
       ) do
    mark_generation_failed(generation)
    reason = rejection_reason(result, opts)

    record_result =
      record_rejected_verdict(
        content_sha,
        github_delivery_id,
        reason,
        result,
        Keyword.put(opts, :generation_id, generation.id)
      )

    case record_result do
      {:ok, entry} ->
        Logger.error(
          "Content promotion failed: #{inspect_promotion_result(result)}"
        )

        {:error, reason, entry}

      {:error, changeset} ->
        Logger.error(
          "Failed to record rejected content verdict: #{inspect(changeset)}"
        )

        {:error, "Publication verdict recording failed"}
    end
  end

  defp handle_sync_error(target_sha, github_delivery_id, reason, opts) do
    record_result =
      record_rejected_verdict(
        target_sha,
        github_delivery_id,
        "Repository sync failed: #{reason_to_string(reason)}",
        empty_result(),
        opts
      )

    case record_result do
      {:ok, entry} ->
        Logger.error("Failed to sync repository: #{reason}")
        {:error, "Repository sync failed", entry}

      :ok ->
        Logger.error("Failed to sync repository: #{reason}")
        {:error, "Repository sync failed"}

      {:error, changeset} ->
        Logger.error(
          "Failed to record rejected content verdict: #{inspect(changeset)}"
        )

        {:error, "Publication verdict recording failed"}
    end
  end

  defp record_accepted_verdict(
         content_sha,
         github_delivery_id,
         generation,
         result,
         opts
       ) do
    record_verdict(content_sha, github_delivery_id, :accepted, result, opts,
      generation_id: generation.id
    )
  end

  defp record_rejected_verdict(nil, github_delivery_id, reason, _result, _opts) do
    Publishing.mark_sync_failed(github_delivery_id, reason)
    :ok
  end

  defp record_rejected_verdict(
         content_sha,
         github_delivery_id,
         reason,
         result,
         opts
       ) do
    record_verdict(content_sha, github_delivery_id, :rejected, result, opts,
      reason: reason,
      generation_id: opts[:generation_id]
    )
  end

  defp record_verdict(
         content_sha,
         github_delivery_id,
         status,
         result,
         opts,
         event_opts
       ) do
    event_opts =
      result
      |> promotion_result_opts(opts)
      |> Keyword.merge(event_opts)
      |> Keyword.put(:repository, Keyword.get(opts, :repository))
      |> Keyword.put(:ref, Keyword.get(opts, :ref))

    Content.record_publication_event(
      github_delivery_id,
      content_sha,
      status,
      event_opts
    )
  end

  defp promotion_result_opts(result, opts) do
    [
      promoted_paths:
        result |> Map.get(:promoted, []) |> repo_relative_paths(opts),
      removed_paths:
        result |> Map.get(:removed, []) |> repo_relative_paths(opts),
      skipped_paths:
        result |> Map.get(:skipped, []) |> repo_relative_paths(opts),
      structured_errors: structured_errors(result, opts)
    ]
  end

  defp structured_errors(result, opts) do
    errors =
      result
      |> Map.get(:errors, [])
      |> Enum.map(fn %{path: path, reason: reason} ->
        %{
          "path" => repo_relative_path(path, opts),
          "reason" => reason_to_string(reason)
        }
      end)

    %{"errors" => errors}
  end

  defp repo_relative_paths(paths, opts) do
    Enum.map(paths, &repo_relative_path(&1, opts))
  end

  defp repo_relative_path(path, opts) when is_binary(path) do
    base_path = Keyword.get(opts, :content_base_path)

    cond do
      is_binary(base_path) and inside_base_path?(path, base_path) ->
        path
        |> Path.expand()
        |> Path.relative_to(Path.expand(base_path))

      String.starts_with?(path, "priv/content/") ->
        String.replace_prefix(path, "priv/content/", "")

      true ->
        String.trim_leading(path, "/")
    end
  end

  defp inside_base_path?(path, base_path)
       when is_binary(path) and is_binary(base_path) do
    expanded_path = Path.expand(path)
    expanded_base_path = Path.expand(base_path)

    expanded_path == expanded_base_path or
      String.starts_with?(expanded_path, expanded_base_path <> "/")
  end

  defp empty_result do
    %{promoted: [], removed: [], skipped: [], errors: []}
  end

  defp add_removed_paths_from_changes(result, local_path, opts) do
    removed_paths =
      opts
      |> Keyword.get(:changes, %{delete: []})
      |> Map.get(:delete, [])
      |> Enum.map(&content_path(local_path, &1))

    %{result | removed: Enum.uniq(removed_paths ++ result.removed)}
  end

  defp content_path(content_base_path, path) do
    path =
      path
      |> String.trim_leading("/")
      |> String.replace_prefix("priv/content/", "")

    Path.expand(path, content_base_path)
  end

  defp duplicate_result do
    empty_result()
    |> Map.put(:duplicate?, true)
  end

  defp delivery_id_before_sync(target_sha, opts) do
    case Keyword.get(opts, :github_delivery_id) do
      nil when is_binary(target_sha) -> github_delivery_id(target_sha, opts)
      nil -> nil
      delivery_id -> delivery_id
    end
  end

  defp github_delivery_id(content_sha, opts) when is_binary(content_sha) do
    Keyword.get(opts, :github_delivery_id) ||
      "#{delivery_id_prefix(opts)}:#{content_sha}"
  end

  defp sync_failure_delivery_id(opts) do
    "#{delivery_id_prefix(opts)}:sync-failed:#{System.unique_integer([:positive])}"
  end

  defp delivery_id_prefix(opts) do
    case Keyword.get(opts, :source) do
      :bootstrap -> "release"
      "bootstrap" -> "release"
      _source -> "manual"
    end
  end

  defp mark_sync_running(nil), do: :ok

  defp mark_sync_running(github_delivery_id) do
    Publishing.mark_sync_running(github_delivery_id)
  end

  defp mark_generation_failed(generation) do
    result =
      generation
      |> Portfolio.Content.Schemas.PublicationGeneration.changeset(%{
        status: "failed"
      })
      |> Portfolio.Repo.update()

    case result do
      {:ok, _generation} ->
        :ok

      {:error, changeset} ->
        Logger.error(
          "Failed to mark content generation failed: #{inspect(changeset)}"
        )
    end
  end

  defp reason_to_string(reason) when is_binary(reason), do: reason
  defp reason_to_string(reason), do: ValidationError.message(reason)

  defp rejection_reason(result, opts) do
    result
    |> Map.get(:errors, [])
    |> List.first()
    |> case do
      %{path: path, reason: reason} ->
        "#{repo_relative_path(path, opts)}: #{reason_to_string(reason)}"

      nil ->
        "Content promotion failed"
    end
  end

  defp inspect_promotion_result(result) do
    result
    |> Map.update(:errors, [], fn errors ->
      Enum.map(errors, fn %{path: path, reason: reason} ->
        %{path: path, reason: reason_to_string(reason)}
      end)
    end)
    |> inspect()
  end
end
