defmodule Portfolio.Content.Remote.GitRepoSyncer do
  @moduledoc """
  Handles synchronization of a Git repository by cloning or pulling updates.
  """

  alias Portfolio.Content.Remote.GitAuth
  alias Portfolio.Content.Remote.GitCommand

  require Logger

  @default_branch "main"

  @type sync_result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Synchronizes the repository by either pulling the latest changes or cloning it.
  """
  @spec sync_repo(String.t(), String.t(), keyword()) :: sync_result()
  def sync_repo(repo_url, local_path, opts \\ []) do
    with {:ok, auth} <- GitAuth.resolve(repo_url, opts) do
      git_command = git_command(opts)

      do_sync_repo(repo_url, local_path, auth, git_command, opts)
    end
  end

  @doc """
  Returns the currently checked-out commit SHA for a local repository.

  This is a bang function because release boot and deploy receipts should fail
  loudly if the local content repository exists but cannot identify its SHA.
  """
  @spec current_sha!(String.t()) :: String.t()
  def current_sha!(local_path) do
    case run_git_command(
           local_path,
           ["rev-parse", "HEAD"],
           GitAuth.none(),
           git_command([])
         ) do
      {:ok, output} -> String.trim(output)
      {:error, reason} -> raise "Failed to read current content SHA: #{reason}"
    end
  end

  @spec do_sync_repo(String.t(), String.t(), GitAuth.t(), module(), keyword()) ::
          sync_result()
  defp do_sync_repo(repo_url, local_path, auth, git_command, opts) do
    if git_repo_exists?(local_path) do
      update_existing_repo(local_path, auth, git_command, opts)
    else
      clone_new_repo(repo_url, local_path, auth, git_command, opts)
    end
  rescue
    # Keep this broad until GitAuth's exception surface is narrower; every
    # escaped message is sanitized before it can reach logs or operator output.
    e ->
      inspected = GitAuth.sanitize(auth, inspect(e))
      message = GitAuth.sanitize(auth, Exception.message(e))

      Logger.error("Failed to sync repo: #{inspected}")
      {:error, "Failed to sync repo: #{message}"}
  end

  @spec git_repo_exists?(String.t()) :: boolean()
  defp git_repo_exists?(path) do
    Logger.debug(fn -> "Checking if repo exists at path: #{path}" end)
    git_dir_exists = File.dir?(Path.join(path, ".git"))
    Logger.debug(fn -> "Git directory exists: #{git_dir_exists}" end)
    git_dir_exists
  end

  @spec update_existing_repo(String.t(), GitAuth.t(), module(), keyword()) ::
          sync_result()
  defp update_existing_repo(local_path, auth, git_command, opts) do
    Logger.info("Updating existing repo at path: #{inspect(local_path)}")

    with {:ok, fetch_output} <- fetch_all(local_path, auth, git_command),
         {:ok, reset_output} <-
           reset_to_target(local_path, auth, git_command, opts),
         {:ok, clean_output} <- clean_repo(local_path, auth, git_command) do
      Logger.debug(fn -> "Fetch output: #{inspect(fetch_output)}" end)
      Logger.debug(fn -> "Reset output: #{inspect(reset_output)}" end)
      Logger.debug(fn -> "Clean output: #{inspect(clean_output)}" end)
      {:ok, local_path}
    else
      {:error, reason} ->
        Logger.error("Failed to update repository: #{reason}")
        {:error, "Failed to update repository: #{reason}"}
    end
  end

  @spec clone_new_repo(String.t(), String.t(), GitAuth.t(), module(), keyword()) ::
          sync_result()
  defp clone_new_repo(repo_url, local_path, auth, git_command, opts) do
    safe_repo_url = GitAuth.sanitize(auth, repo_url)

    Logger.info("Cloning new repo: #{safe_repo_url} to path: #{local_path}")

    temp_path = temp_clone_path(local_path)

    with :ok <- ensure_parent_dir(local_path),
         :ok <- remove_path(temp_path),
         {:ok, _temp_path} <-
           clone_to_path(repo_url, temp_path, auth, git_command),
         {:ok, _reset_output} <-
           reset_to_target(temp_path, auth, git_command, opts),
         {:ok, _clean_output} <- clean_repo(temp_path, auth, git_command),
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

  defp clone_to_path(repo_url, target_path, auth, git_command) do
    Logger.debug("Running git clone with verbose output")

    case git_command.run("git", ["clone", "--verbose", repo_url, target_path],
           env: GitAuth.env(auth),
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        output = GitAuth.sanitize(auth, output)

        Logger.debug(fn -> "Clone succeeded with output: #{output}" end)
        {:ok, target_path}

      {output, code} ->
        output = GitAuth.sanitize(auth, output)

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

  @spec fetch_all(String.t(), GitAuth.t(), module()) :: sync_result()
  defp fetch_all(path, auth, git_command),
    do:
      run_git_command(path, ["fetch", "--all", "--verbose"], auth, git_command)

  @spec reset_to_origin(String.t(), GitAuth.t(), module()) :: sync_result()
  defp reset_to_origin(path, auth, git_command),
    do:
      run_git_command(
        path,
        ["reset", "--hard", "origin/#{@default_branch}"],
        auth,
        git_command
      )

  @spec reset_to_target(String.t(), GitAuth.t(), module(), keyword()) ::
          sync_result()
  defp reset_to_target(path, auth, git_command, opts) do
    case Keyword.get(opts, :target_sha) do
      sha when is_binary(sha) and sha != "" ->
        run_git_command(path, ["reset", "--hard", sha], auth, git_command)

      _ ->
        reset_to_origin(path, auth, git_command)
    end
  end

  @spec clean_repo(String.t(), GitAuth.t(), module()) :: sync_result()
  # Use -x so ignored stale Markdown cannot survive reset and be published as
  # if it belonged to the checked-out content SHA.
  defp clean_repo(path, auth, git_command),
    do: run_git_command(path, ["clean", "-ffdx"], auth, git_command)

  defp run_git_command(path, args, auth, git_command) do
    full_args = ["-C", path | args]

    Logger.debug(fn ->
      "Running git command. Path: #{inspect(path)}, Args: #{inspect(args)}, Full args: #{inspect(full_args)}"
    end)

    case git_command.run("git", full_args,
           env: GitAuth.env(auth),
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        output = GitAuth.sanitize(auth, output)

        Logger.debug(fn ->
          "Git command succeeded with output: #{inspect(output)}"
        end)

        {:ok, output}

      {output, code} ->
        output = GitAuth.sanitize(auth, output)

        Logger.error(
          "Git command failed with exit code #{code}, output: #{inspect(output)}"
        )

        {:error, output}
    end
  end

  @spec git_command(keyword()) :: module()
  defp git_command(opts) do
    Keyword.get(opts, :git_command) ||
      Application.get_env(
        :portfolio,
        :git_command,
        GitCommand.System
      )
  end
end
