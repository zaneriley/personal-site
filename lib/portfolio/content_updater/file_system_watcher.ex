defmodule Portfolio.ContentUpdater.FileSystemWatcher do
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
    paths = Application.get_env(:portfolio, Portfolio.ContentUpdater.FileSystemWatcher)[:paths]
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
    cond do
      events in [:modified, :closed] ->
        Logger.debug("File modified: #{path}")
        # Trigger your content update logic here

      events == [:created] ->
        Logger.debug("File created: #{path}")
        # Optionally handle file creation if needed

      true ->
        # Other events – log them if it helps in development
        Logger.debug("File system event: Path: #{path}, Events: #{inspect(events)}")
    end

    {:noreply, state}
  end
end
