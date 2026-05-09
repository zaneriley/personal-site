defmodule Portfolio.Content.Remote.GitRepoSyncer do
  @moduledoc """
  Handles synchronization of a Git repository by cloning or pulling updates.
  """

  require Logger

  @git_env [
    {"GIT_TERMINAL_PROMPT", "0"}
  ]
  @default_branch "main"

  @type sync_result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Synchronizes the repository by either pulling the latest changes or cloning it.
  """
  @spec sync_repo(String.t(), String.t(), keyword()) :: sync_result()
  def sync_repo(repo_url, local_path, opts \\ []) do
    do_sync_repo(repo_url, local_path, opts)
  end

  @doc """
  Returns the currently checked-out commit SHA for a local repository.
  """
  @spec current_sha!(String.t()) :: String.t()
  def current_sha!(local_path) do
    case run_git_command(local_path, ["rev-parse", "HEAD"]) do
      {:ok, output} -> String.trim(output)
      {:error, reason} -> raise "Failed to read current content SHA: #{reason}"
    end
  end

  @spec do_sync_repo(String.t(), String.t(), keyword()) :: sync_result()
  defp do_sync_repo(repo_url, local_path, opts) do
    if git_repo_exists?(local_path) do
      update_existing_repo(local_path, opts)
    else
      clone_new_repo(repo_url, local_path, opts)
    end
  rescue
    e ->
      Logger.error("Failed to sync repo: #{inspect(e)}")
      {:error, "Failed to sync repo: #{Exception.message(e)}"}
  end

  @spec git_repo_exists?(String.t()) :: boolean()
  defp git_repo_exists?(path) do
    Logger.debug("Checking if repo exists at path: #{path}")
    git_dir_exists = File.dir?(Path.join(path, ".git"))
    Logger.debug("Git directory exists: #{git_dir_exists}")
    git_dir_exists
  end

  @spec update_existing_repo(String.t(), keyword()) :: sync_result()
  defp update_existing_repo(local_path, opts) do
    Logger.info("Updating existing repo at path: #{inspect(local_path)}")

    with {:ok, fetch_output} <- fetch_all(local_path),
         {:ok, reset_output} <- reset_to_target(local_path, opts),
         {:ok, clean_output} <- clean_repo(local_path) do
      Logger.debug("Fetch output: #{inspect(fetch_output)}")
      Logger.debug("Reset output: #{inspect(reset_output)}")
      Logger.debug("Clean output: #{inspect(clean_output)}")
      {:ok, local_path}
    else
      {:error, reason} ->
        Logger.error("Failed to update repository: #{reason}")
        {:error, "Failed to update repository: #{reason}"}
    end
  end

  @spec clone_new_repo(String.t(), String.t(), keyword()) :: sync_result()
  defp clone_new_repo(repo_url, local_path, opts) do
    Logger.info("Cloning new repo: #{repo_url} to path: #{local_path}")

    temp_path = temp_clone_path(local_path)

    with :ok <- ensure_parent_dir(local_path),
         :ok <- remove_path(temp_path),
         {:ok, _temp_path} <- clone_to_path(repo_url, temp_path),
         {:ok, _reset_output} <- reset_to_target(temp_path, opts),
         {:ok, _clean_output} <- clean_repo(temp_path),
         :ok <- replace_local_path(temp_path, local_path) do
      {:ok, local_path}
    else
      {:error, reason} = error ->
        Logger.error("Failed to clone repository: #{reason}")
        remove_path(temp_path)
        error
    end
  end

  defp ensure_parent_dir(local_path) do
    local_path
    |> Path.dirname()
    |> File.mkdir_p()
  end

  defp temp_clone_path(local_path) do
    local_path <> ".clone-#{System.unique_integer([:positive])}"
  end

  defp clone_to_path(repo_url, target_path) do
    Logger.debug("Running git clone with verbose output")

    case System.cmd("git", ["clone", "--verbose", repo_url, target_path],
           env: @git_env,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        Logger.debug("Clone succeeded with output: #{output}")
        {:ok, target_path}

      {output, code} ->
        {:error, "exit code #{code}, output: #{output}"}
    end
  end

  defp replace_local_path(temp_path, local_path) do
    with :ok <- remove_path(local_path) do
      File.rename(temp_path, local_path)
    end
  end

  defp remove_path(path) do
    case File.rm_rf(path) do
      {:ok, _files} ->
        :ok

      {:error, reason, failed_path} ->
        {:error, "failed to remove #{failed_path}: #{reason}"}
    end
  end

  @spec fetch_all(String.t()) :: sync_result()
  defp fetch_all(path),
    do: run_git_command(path, ["fetch", "--all", "--verbose"])

  @spec reset_to_origin(String.t()) :: sync_result()
  defp reset_to_origin(path),
    do: run_git_command(path, ["reset", "--hard", "origin/#{@default_branch}"])

  @spec reset_to_target(String.t(), keyword()) :: sync_result()
  defp reset_to_target(path, opts) do
    case Keyword.get(opts, :target_sha) do
      sha when is_binary(sha) and sha != "" ->
        run_git_command(path, ["reset", "--hard", sha])

      _ ->
        reset_to_origin(path)
    end
  end

  @spec clean_repo(String.t()) :: sync_result()
  defp clean_repo(path), do: run_git_command(path, ["clean", "-fd"])

  defp run_git_command(path, args) do
    full_args = ["-C", path | args]

    Logger.debug(
      "Running git command. Path: #{inspect(path)}, Args: #{inspect(args)}, Full args: #{inspect(full_args)}"
    )

    Enum.each(full_args, fn arg ->
      Logger.debug("Arg: #{inspect(arg)}, Type: #{inspect(typeof(arg))}")
    end)

    case System.cmd("git", full_args, env: @git_env, stderr_to_stdout: true) do
      {output, 0} ->
        Logger.debug("Git command succeeded with output: #{inspect(output)}")
        {:ok, output}

      {output, code} ->
        Logger.error(
          "Git command failed with exit code #{code}, output: #{inspect(output)}"
        )

        {:error, output}
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
