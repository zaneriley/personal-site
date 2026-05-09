defmodule Portfolio.Release do
  @moduledoc """
  This module defines functions that you can run with releases.
  """

  alias Portfolio.Content
  alias Portfolio.Content.FileManagement.Promoter
  alias Portfolio.Content.Remote.RemoteUpdateTrigger

  require Logger

  @app :portfolio

  @spec migrate() :: [term()]
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @doc """
  Pulls the latest changes from the configured repository.
  """
  @spec pull_repository() :: :ok | no_return()
  def pull_repository do
    {:ok, _apps} = Application.ensure_all_started(@app)

    with {:ok, repo_url} <- get_content_repo_url(),
         {:ok, local_path} <- get_content_base_path(),
         :ok <- do_pull_repository(repo_url, local_path) do
      :ok
    else
      {:error, reason} -> handle_bootstrap_failure(reason)
    end
  end

  defp do_pull_repository(repo_url, local_path) do
    case RemoteUpdateTrigger.trigger_update(repo_url,
           content_base_path: local_path,
           repository: repo_url,
           ref: "refs/heads/main",
           source: :bootstrap
         ) do
      {:ok, _result} ->
        Logger.info(
          "Successfully published latest content from the repository."
        )

        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_bootstrap_failure(reason) do
    if content_ready_for_bootstrap?() do
      Logger.error(
        "Failed to publish repository at boot, serving last-good content: #{reason}"
      )

      :ok
    else
      Logger.error(
        "Failed to publish repository at boot and no last-good content exists: #{reason}"
      )

      raise "Failed to publish repository at boot and no last-good content exists: #{reason}"
    end
  end

  defp content_ready_for_bootstrap? do
    case Application.ensure_all_started(@app) do
      {:ok, _apps} ->
        Content.content_ready?()

      {:error, reason} ->
        Logger.error(
          "Could not check last-good content during boot failure: #{inspect(reason)}"
        )

        false
    end
  rescue
    error ->
      Logger.error(
        "Could not check last-good content during boot failure: #{Exception.message(error)}"
      )

      false
  end

  @doc """
  Reads all existing markdown files and updates the database.
  """
  @spec read_existing_content() :: :ok | no_return()
  def read_existing_content do
    with :ok <- load_app(),
         {:ok, content_base_path} <- get_content_base_path(),
         :ok <- publish_embedded_content(content_base_path) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to read existing content: #{inspect(reason)}")
        handle_bootstrap_failure(reason)
    end
  end

  defp get_content_repo_url do
    case Application.get_env(:portfolio, :content_repo_url) do
      nil ->
        {:error,
         "Missing configuration for content_repo_url. " <>
           "Ensure CONTENT_REPO_URL environment variable is set."}

      path when is_binary(path) ->
        {:ok, path}

      invalid ->
        {:error,
         "Invalid configuration for content_repo_url: #{inspect(invalid)}"}
    end
  end

  defp get_content_base_path do
    case Application.get_env(:portfolio, :content_base_path) do
      nil ->
        {:error,
         "Missing configuration for content_base_path. Check your config files."}

      path when is_binary(path) ->
        {:ok, path}

      invalid ->
        {:error,
         "Invalid configuration for content_base_path: #{inspect(invalid)}"}
    end
  end

  defp publish_embedded_content(content_base_path) do
    {:ok, _apps} = Application.ensure_all_started(@app)
    content_sha = embedded_content_sha(content_base_path)

    Portfolio.Content.Publishing.with_publication_lock(fn ->
      with {:ok, generation} <-
             Portfolio.Content.Publishing.prepare_generation(content_sha,
               source: :bootstrap
             ),
           {:ok, result} <-
             Promoter.promote_all(content_base_path,
               publication_generation_id: generation.id
             ),
           {:ok, _entry} <-
             Content.record_publication_event(
               "embedded:#{content_sha}",
               content_sha,
               :accepted,
               generation_id: generation.id,
               promoted_paths: result.promoted,
               removed_paths: result.removed,
               skipped_paths: result.skipped,
               structured_errors: %{"errors" => []},
               reason: "Embedded content bootstrap"
             ) do
        :ok
      else
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  defp embedded_content_sha(content_base_path) do
    content_base_path
    |> Path.join("**/*.md")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(fn path -> [path, "\0", File.read!(path), "\0"] end)
    |> then(&:crypto.hash(:sha, &1))
    |> Base.encode16(case: :lower)
  end

  @spec rollback(module(), non_neg_integer()) :: {:ok, term(), [atom()]}
  def rollback(repo, version) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    case Application.load(@app) do
      :ok -> :ok
      {:error, {:already_loaded, @app}} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
