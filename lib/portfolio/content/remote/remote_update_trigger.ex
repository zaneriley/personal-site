defmodule Portfolio.Content.Remote.RemoteUpdateTrigger do
  @moduledoc """
  Manages remote content updates and triggers file processing.

  This module is responsible for:
  - Syncing remote Git repositories
  - Handling updates for changed files
  - Processing individual files and updating the local content

  It uses `GitContentFetcher` to fetch remote content, `Reader` to parse markdown files,
  and `Watcher` to process file changes.
  """

  alias Portfolio.Content.Remote.GitContentFetcher
  alias Portfolio.Content.Remote.GitRepoSyncer
  alias Portfolio.Content.FileManagement.Reader
  alias Portfolio.Content.FileManagement.Watcher
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

    - `{:ok, :updated}` if the sync was successful.
    - `{:error, reason}` if the sync failed.
  """
  @spec trigger_update(String.t()) :: {:ok, :updated} | {:error, String.t()}
  def trigger_update(repo_url) do
    local_path = Application.get_env(:portfolio, :content_base_path)

    case GitRepoSyncer.sync_repo(repo_url, local_path) do
      {:ok, _} ->
        {:ok, :updated}

      {:error, reason} ->
        Logger.error("Failed to sync repository: #{reason}")
        {:error, "Repository sync failed"}
    end
  end

  @doc false
  @spec process_file(String.t(), String.t()) :: {:ok, map()} | {:error, any()}
  defp process_file(path, content) do
    case Reader.read_markdown_file(content) do
      {:ok, _content_type, parsed_content} ->
        case Watcher.process_file_change(path, parsed_content) do
          :ok -> {:ok, %{path: path, content: content}}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
