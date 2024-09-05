defmodule Portfolio.Content.Remote.GitRepoSyncer do
  @moduledoc """
  Handles synchronization of a Git repository by cloning or pulling updates.
  """

  require Logger

  @git_env [{"GIT_TERMINAL_PROMPT", "0"}]
  @default_branch "main"

  @type sync_result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Synchronizes the repository by either pulling the latest changes or cloning it.
  """
  @spec sync_repo(String.t(), String.t()) :: sync_result()
  def sync_repo(repo_url, local_path) do
    Logger.info("Starting sync for repo: #{repo_url} at path: #{local_path}")

    result = do_sync_repo(repo_url, local_path)

    Logger.info(
      "Finished sync for repo: #{repo_url} with result: #{inspect(result)}"
    )

    result
  end

  @spec do_sync_repo(String.t(), String.t()) :: sync_result()
  defp do_sync_repo(repo_url, local_path) do
    if repo_exists?(local_path) do
      update_existing_repo(local_path)
    else
      clone_new_repo(repo_url, local_path)
    end
  rescue
    e ->
      Logger.error("Failed to sync repo: #{inspect(e)}")
      {:error, "Failed to sync repo: #{Exception.message(e)}"}
  end

  @spec repo_exists?(String.t()) :: boolean()
  defp repo_exists?(path) do
    Logger.debug("Checking if repo exists at path: #{path}")
    File.dir?(path)
  end

  @spec update_existing_repo(String.t()) :: sync_result()
  defp update_existing_repo(local_path) do
    Logger.info("Updating existing repo at path: #{inspect(local_path)}")

    with {:ok, _} <- fetch_all(local_path),
         {:ok, _} <- reset_to_origin(local_path),
         {:ok, _} <- clean_repo(local_path) do
      {:ok, local_path}
    else
      {:error, reason} ->
        Logger.error("Failed to update repository: #{reason}")
        {:error, "Failed to update repository: #{reason}"}
    end
  end

  @spec clone_new_repo(String.t(), String.t()) :: sync_result()
  defp clone_new_repo(repo_url, local_path) do
    Logger.info("Cloning new repo: #{repo_url} to path: #{local_path}")

    case System.cmd("git", ["clone", repo_url, local_path], env: @git_env) do
      {_, 0} ->
        {:ok, local_path}

      {output, _} ->
        Logger.error("Failed to clone repository: #{output}")
        {:error, "Failed to clone repository: #{output}"}
    end
  end

  @spec fetch_all(String.t()) :: sync_result()
  defp fetch_all(path), do: run_git_command(path, ["fetch", "--all"])

  @spec reset_to_origin(String.t()) :: sync_result()
  defp reset_to_origin(path),
    do: run_git_command(path, ["reset", "--hard", "origin/#{@default_branch}"])

  @spec clean_repo(String.t()) :: sync_result()
  defp clean_repo(path), do: run_git_command(path, ["clean", "-fd"])

  defp run_git_command(path, args) do
    full_args = ["-C", path | args]
    Logger.debug("Running git command. Path: #{inspect(path)}, Args: #{inspect(args)}, Full args: #{inspect(full_args)}")

    Enum.each(full_args, fn arg ->
      Logger.debug("Arg: #{inspect(arg)}, Type: #{inspect(typeof(arg))}")
    end)

    case System.cmd("git", full_args, env: @git_env) do
      {_, 0} -> {:ok, path}
      {output, _} -> {:error, output}
    end
  end

  defp typeof(term) do
    cond do
      is_binary(term) -> "binary"
      is_list(term) -> "list"
      is_atom(term) -> "atom"
      is_integer(term) -> "integer"
      true -> "other"
    end
  end
end
