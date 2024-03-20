defmodule Portfolio.Content.FileSystemWatcher do
  use GenServer
  require Logger

  @doc """
  Monitors a specified directory for file changes and triggers content updates.
  """
  def start_link(paths) do
    GenServer.start_link(__MODULE__, paths, name: __MODULE__)
  end

  @doc """
  Initializes the file watcher.

  Args:
    * paths: A list of directory paths to watch.

  Returns:
    {:ok, pid} where pid is the process ID of the file watcher.
  """
  def init(paths) do
    paths = Application.get_env(:portfolio, Portfolio.Content.FileSystemWatcher)[:paths]
    {:ok, watcher_pid} = FileSystem.start_link(dirs: paths)
    Logger.info("File system watcher started, watching paths: #{inspect(paths)}")
    FileSystem.subscribe(watcher_pid)
    {:ok, %{watcher_pid: watcher_pid}}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid}=state) do
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
  def handle_info({:file_event, watcher_pid, {path, events}}, %{watcher_pid: watcher_pid} = state) do
    # Enhanced logging: Include event information
    Logger.info("File system event: File: #{path}, Events: #{inspect(events)}")

    if relevant_file_change?(path, events) do
      Logger.info("relevant file change detected: #{path}")
      case Portfolio.Content.update_case_study_from_file(path) do
        {:ok, _} -> Logger.info("File change processed successfully")

        {:error, reason} ->
          Logger.error("Failed to update case study from file: #{path}. Reason: #{inspect(reason)}")
      end
    else
      # Original logging for non-relevant changes
      Logger.debug("Not relevant file change: #{inspect(relevant_file_change?(path, events))}")
    end

    {:noreply, state}
  end

  def handle_info(unknown_message, state) do
    Logger.warn("Received unknown message: #{inspect(unknown_message)}")
    Logger.warn("State: #{inspect(state)}")
    {:noreply, state}
  end

  defp relevant_file_change?(path, events) do
    Path.extname(path) == ".md" and
    events == [:modified, :closed] and
    not String.starts_with?(path, ".")
  end
end
