defmodule Portfolio.Content.FileSystemWatcher do
  @moduledoc """
  A GenServer that monitors a specified directory for file changes, particularly Markdown files.

  The GenServer is responsible for handling file system events and triggering content updates when relevant files are detected.

  ## Usage

  To use the FileSystemWatcher, start the GenServer with the `paths` option set to the directory paths you want to monitor. The GenServer will then monitor the specified directories for file changes and trigger content updates when relevant files are detected.

  ## Implementation

  - Utilizes the `FileSystem` library for watching file system events.
  - Filters events to react only to modifications of Markdown files that are not hidden.
  - Updates the content of the relevant case studies based on the file changes.
  """

  use GenServer
  require Logger

  @doc """
  Monitors a specified directory for file changes and triggers content updates.
  """
  def start_link(paths) do
    if should_start?() do
      GenServer.start_link(__MODULE__, paths, name: __MODULE__)
    else
      :ignore
    end
  end

  defp should_start? do
    Application.get_env(:portfolio, :environment) in [:dev, :test]
  end

  @doc """
  Initializes the file watcher.

  Args:
    * paths: A list of directory paths to watch.

  Returns:
    {:ok, pid} where pid is the process ID of the file watcher.
  """
  def init(_paths) do
    paths =
      Application.get_env(:portfolio, Portfolio.Content.FileSystemWatcher)[
        :paths
      ]

    {:ok, watcher_pid} = FileSystem.start_link(dirs: paths)

    Logger.info(
      "File system watcher started, watching paths: #{inspect(paths)}"
    )

    FileSystem.subscribe(watcher_pid)
    {:ok, %{watcher_pid: watcher_pid}}
  end

  def handle_info(
        {:file_event, watcher_pid, :stop},
        %{watcher_pid: watcher_pid} = state
      ) do
    Logger.warning("File system watcher stopped unexpectedly")
    {:noreply, state}
  end

  @doc """
  Handles file change notifications. Triggers content updates.

  Args:
    * notification: A tuple of the format: {:file_event, watcher_pid, {path, events}} where
                - path: String representing the file path that changed
                - events: A list of file system events (e.g., [:modified, :created])
    * state: The current state of the file watcher GenServer.

  """
  def handle_info(
        {:file_event, watcher_pid, {path, events}},
        %{watcher_pid: watcher_pid} = state
      ) do
    Logger.info("File system event: File: #{path}, Events: #{inspect(events)}")

    case {relevant_file_change?(path, events), events} do
      {true, [:modified]} ->
        process_file_change(path, state)

      {true, [:modified, :closed]} ->
        process_file_change(path, state)

      {false, _} ->
        Logger.debug("Ignored file change: #{path}")
        {:noreply, state}

      _ ->
        Logger.debug("Unhandled file event pattern: #{inspect(events)}")
        {:noreply, state}
    end
  end

  def process_file_change(path, state) do
    Logger.info("Processing file change for: #{path}")

    case Portfolio.Content.update_case_study_from_file(path) do
      {:ok, _} ->
        Logger.info("File change processed successfully for: #{path}")
        {:noreply, state}

      {:error, reason} ->
        Logger.error("Error processing file change: #{inspect(reason)}")
        {:noreply, Map.put(state, :last_error, reason)}
    end
  end

  defp handle_error(reason, state) do
    Logger.error("Error processing file change: #{inspect(reason)}")
    {:noreply, Map.put(state, :last_error, reason)}
  end

  def relevant_file_change?(path, events) do
    Path.extname(path) == ".md" and
      not String.starts_with?(Path.basename(path), ".") and
      (:modified in events or :created in events or [:closed] == events)
  end

  def start_link() do
    raise "File system watcher is not available in #{Mix.env()} environment"
    :ignore
  end
end
