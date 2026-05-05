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
  @spec sync_repo(String.t(), String.t()) :: sync_result()
  def sync_repo(repo_url, local_path) do
    do_sync_repo(repo_url, local_path)
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
    dir_exists = File.dir?(path)
    Logger.debug("Directory exists: #{dir_exists}")
    dir_exists
  end

  @spec update_existing_repo(String.t()) :: sync_result()
  defp update_existing_repo(local_path) do
    Logger.info("Updating existing repo at path: #{inspect(local_path)}")

    with {:ok, fetch_output} <- fetch_all(local_path),
         {:ok, reset_output} <- reset_to_origin(local_path),
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

  @spec clone_new_repo(String.t(), String.t()) :: sync_result()
  defp clone_new_repo(repo_url, local_path) do
    Logger.info("Cloning new repo: #{repo_url} to path: #{local_path}")

    # Ensure the parent directory exists
    parent_dir = Path.dirname(local_path)

    if !File.exists?(parent_dir) do
      Logger.debug("Creating parent directory: #{parent_dir}")
      File.mkdir_p!(parent_dir)
    end

    Logger.debug("Running git clone with verbose output")

    case System.cmd("git", ["clone", "--verbose", repo_url, local_path],
           env: @git_env,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        Logger.debug("Clone succeeded with output: #{output}")
        {:ok, local_path}

      {output, code} ->
        Logger.error(
          "Failed to clone repository: exit code #{code}, output: #{output}"
        )

        {:error, "Failed to clone repository: #{output}"}
    end
  end

  @spec fetch_all(String.t()) :: sync_result()
  defp fetch_all(path),
    do: run_git_command(path, ["fetch", "--all", "--verbose"])

  @spec reset_to_origin(String.t()) :: sync_result()
  defp reset_to_origin(path),
    do: run_git_command(path, ["reset", "--hard", "origin/#{@default_branch}"])

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
