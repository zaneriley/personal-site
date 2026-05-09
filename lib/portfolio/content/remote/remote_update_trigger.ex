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

  use GenServer

  alias Portfolio.Content
  alias Portfolio.Content.FileManagement.Promoter
  alias Portfolio.Content.Publishing
  alias Portfolio.Content.Remote.GitRepoSyncer

  require Logger

  @doc """
  Starts the RemoteUpdateTrigger process.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  @spec init(keyword()) :: {:ok, map()}
  def init(_opts) do
    {:ok, %{}}
  end

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
    case Process.whereis(__MODULE__) do
      nil ->
        perform_update(repo_url, opts)

      _pid ->
        GenServer.call(__MODULE__, {:trigger_update, repo_url, opts}, :infinity)
    end
  end

  @impl true
  def handle_call({:trigger_update, repo_url, opts}, _from, state) do
    {:reply, perform_update(repo_url, opts), state}
  end

  defp perform_update(repo_url, opts) do
    local_path =
      Keyword.get(opts, :content_base_path) ||
        Application.get_env(:portfolio, :content_base_path)

    target_sha = Keyword.get(opts, :target_sha)
    github_delivery_id = delivery_id_before_sync(target_sha, opts)

    Publishing.with_publication_lock(fn ->
      if duplicate_delivery?(github_delivery_id) do
        Logger.info("Duplicate content delivery ignored: #{github_delivery_id}")
        {:ok, duplicate_result()}
      else
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
  end

  defp sync_and_promote(
         repo_url,
         local_path,
         target_sha,
         github_delivery_id,
         opts
       ) do
    case GitRepoSyncer.sync_repo(repo_url, local_path, target_sha: target_sha) do
      {:ok, _} ->
        content_sha = target_sha || GitRepoSyncer.current_sha!(local_path)

        github_delivery_id =
          github_delivery_id || github_delivery_id(content_sha, opts)

        if duplicate_delivery?(github_delivery_id) do
          Logger.info(
            "Duplicate content delivery ignored: #{github_delivery_id}"
          )

          {:ok, duplicate_result()}
        else
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
           rollback_on_error: false
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
      :ok ->
        Logger.info("Content promotion completed: #{inspect(result)}")
        {:ok, result}

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

    record_rejected_verdict(
      content_sha,
      github_delivery_id,
      "Content promotion failed",
      result,
      Keyword.put(opts, :generation_id, generation.id)
    )

    Logger.error("Content promotion failed: #{inspect(result)}")
    {:error, "Content promotion failed"}
  end

  defp handle_sync_error(target_sha, github_delivery_id, reason, opts) do
    record_rejected_verdict(
      target_sha,
      github_delivery_id,
      "Repository sync failed: #{reason_to_string(reason)}",
      empty_result(),
      opts
    )

    Logger.error("Failed to sync repository: #{reason}")
    {:error, "Repository sync failed"}
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
    opts =
      result
      |> promotion_result_opts()
      |> Keyword.merge(event_opts)
      |> Keyword.put(:repository, Keyword.get(opts, :repository))
      |> Keyword.put(:ref, Keyword.get(opts, :ref))

    case Content.record_publication_event(
           github_delivery_id,
           content_sha,
           status,
           opts
         ) do
      {:ok, _entry} -> :ok
      {:duplicate, _entry} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp promotion_result_opts(result) do
    [
      promoted_paths: Map.get(result, :promoted, []),
      removed_paths: Map.get(result, :removed, []),
      skipped_paths: Map.get(result, :skipped, []),
      structured_errors: structured_errors(result)
    ]
  end

  defp structured_errors(result) do
    errors =
      result
      |> Map.get(:errors, [])
      |> Enum.map(fn %{path: path, reason: reason} ->
        %{"path" => path, "reason" => reason_to_string(reason)}
      end)

    %{"errors" => errors}
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

  defp duplicate_delivery?(nil), do: false

  defp duplicate_delivery?(github_delivery_id) do
    not is_nil(Publishing.get_ledger_entry_by_delivery_id(github_delivery_id))
  end

  defp mark_sync_running(nil), do: :ok

  defp mark_sync_running(github_delivery_id) do
    Publishing.mark_sync_running(github_delivery_id)
  end

  defp mark_generation_failed(generation) do
    generation
    |> Portfolio.Content.Schemas.PublicationGeneration.changeset(%{
      status: "failed"
    })
    |> Portfolio.Repo.update()
  end

  defp reason_to_string(reason) when is_binary(reason), do: reason
  defp reason_to_string(reason), do: inspect(reason)
end
