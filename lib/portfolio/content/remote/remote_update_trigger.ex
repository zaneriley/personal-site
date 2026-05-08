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
  alias Portfolio.Content.Remote.GitRepoSyncer

  require Logger

  @doc """
  Starts the RemoteUpdateTrigger agent.
  """
  @spec start_link(any()) :: Agent.on_start()
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
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
    local_path =
      Keyword.get(opts, :content_base_path) ||
        Application.get_env(:portfolio, :content_base_path)

    changes = Keyword.get(opts, :changes, %{upsert: [], delete: []})

    target_sha = Keyword.get(opts, :target_sha)

    case GitRepoSyncer.sync_repo(repo_url, local_path, target_sha: target_sha) do
      {:ok, _} ->
        promote_synced_content(local_path, changes, target_sha)

      {:error, reason} ->
        handle_sync_error(target_sha, reason)
    end
  end

  defp promote_synced_content(local_path, changes, target_sha) do
    case Promoter.promote_changes(local_path, changes) do
      {:ok, result} ->
        handle_promotion_success(target_sha, result)

      {:error, result} ->
        handle_promotion_error(target_sha, result)
    end
  end

  defp handle_promotion_success(target_sha, result) do
    case record_accepted_verdict(target_sha, result) do
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

  defp handle_promotion_error(target_sha, result) do
    record_rejected_verdict(
      target_sha,
      "Content promotion failed",
      result
    )

    Logger.error("Content promotion failed: #{inspect(result)}")
    {:error, "Content promotion failed"}
  end

  defp handle_sync_error(target_sha, reason) do
    record_rejected_verdict(
      target_sha,
      "Repository sync failed: #{reason_to_string(reason)}"
    )

    Logger.error("Failed to sync repository: #{reason}")
    {:error, "Repository sync failed"}
  end

  defp record_accepted_verdict(nil, _result), do: :ok

  defp record_accepted_verdict(content_sha, result) do
    record_verdict(content_sha, :accepted, result)
  end

  defp record_rejected_verdict(nil, _reason), do: :ok

  defp record_rejected_verdict(content_sha, reason) do
    record_verdict(content_sha, :rejected, empty_result(), reason)
  end

  defp record_rejected_verdict(content_sha, reason, result) do
    record_verdict(content_sha, :rejected, result, reason)
  end

  defp record_verdict(content_sha, status, result, reason \\ nil) do
    opts =
      result
      |> promotion_result_opts()
      |> Keyword.put(:reason, reason)

    case Content.record_publication_verdict(content_sha, status, opts) do
      {:ok, _verdict} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp promotion_result_opts(result) do
    [
      promoted_paths: Map.get(result, :promoted, []),
      removed_paths: Map.get(result, :removed, []),
      skipped_paths: Map.get(result, :skipped, []),
      error_details: error_details(result)
    ]
  end

  defp error_details(result) do
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

  defp reason_to_string(reason) when is_binary(reason), do: reason
  defp reason_to_string(reason), do: inspect(reason)
end
