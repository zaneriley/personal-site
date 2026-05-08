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

    case GitRepoSyncer.sync_repo(repo_url, local_path,
           target_sha: Keyword.get(opts, :target_sha)
         ) do
      {:ok, _} ->
        case Promoter.promote_changes(local_path, changes) do
          {:ok, result} ->
            Logger.info("Content promotion completed: #{inspect(result)}")
            {:ok, result}

          {:error, result} ->
            Logger.error("Content promotion failed: #{inspect(result)}")
            {:error, "Content promotion failed"}
        end

      {:error, reason} ->
        Logger.error("Failed to sync repository: #{reason}")
        {:error, "Repository sync failed"}
    end
  end
end
