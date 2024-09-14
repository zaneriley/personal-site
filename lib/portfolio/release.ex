defmodule Portfolio.Release do
  @moduledoc """
  This module defines functions that you can run with releases.
  """

  @app :portfolio
  alias Portfolio.Content
  alias Portfolio.Content.FileManagement.Reader
  alias Portfolio.Content.Remote.GitRepoSyncer
  require Logger

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
  def pull_repository do
    repo_url = Application.get_env(:portfolio, :content_repo_url)
    local_path = Application.get_env(:portfolio, :content_base_path)

    IO.puts("Debug: repo_url = #{inspect(repo_url)}")
    IO.puts("Debug: local_path = #{inspect(local_path)}")

    cond do
      is_nil(repo_url) ->
        raise "Missing configuration for content_repo_url. Ensure CONTENT_REPO_URL environment variable is set."

      is_nil(local_path) ->
        raise "Missing configuration for content_base_path. Check your config files."

      not is_binary(repo_url) ->
        raise "Invalid configuration for content_repo_url: #{inspect(repo_url)}. It should be a string."

      not is_binary(local_path) ->
        raise "Invalid configuration for content_base_path: #{inspect(local_path)}. It should be a string."

      true ->
        do_pull_repository(repo_url, local_path)
    end
  end

  defp do_pull_repository(repo_url, local_path) do
    case GitRepoSyncer.sync_repo(repo_url, local_path) do
      {:ok, _} ->
        Logger.info("Successfully pulled latest changes from the repository.")

      {:error, reason} ->
        Logger.error("Failed to pull repository: #{reason}")
        raise "Failed to pull repository: #{reason}"
    end
  end

  @doc """
  Reads all existing markdown files and updates the database.
  """
  def read_existing_content do
    with :ok <- load_app(),
         {:ok, content_base_path} <- get_content_base_path(),
         {:ok, files} <- list_files(content_base_path) do
      files
      |> Enum.filter(&markdown?/1)
      |> Enum.each(&process_file(Path.join(content_base_path, &1)))
    else
      {:error, reason} ->
        Logger.error("Failed to read existing content: #{inspect(reason)}")
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

  defp list_files(path) do
    case File.ls(path) do
      {:ok, files} ->
        {:ok, files}

      {:error, reason} ->
        {:error, "Failed to list files in #{path}: #{inspect(reason)}"}
    end
  end

  defp markdown?(file_name) do
    String.ends_with?(file_name, ".md")
  end

  defp process_file(file_path) do
    case Reader.read_markdown_file(file_path) do
      {:ok, content_type, attrs} ->
        case Content.upsert_from_file(content_type, attrs) do
          {:ok, _content} ->
            Logger.info("Successfully upserted content from file: #{file_path}")

          {:error, reason} ->
            Logger.error(
              "Error upserting content from file #{file_path}: #{inspect(reason)}"
            )
        end

      {:error, reason} ->
        Logger.error("Error processing file #{file_path}: #{inspect(reason)}")
    end
  end

  def rollback(repo, version) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
