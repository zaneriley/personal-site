defmodule Portfolio.Content.FileManagement.Watcher do
  @moduledoc """
  Monitors file system changes for markdown content files.

  Uses FileSystem to watch specified directories, processes relevant file events,
  and triggers content updates through the Reader module and Content context.
  """

  use GenServer
  require Logger
  alias Portfolio.Content.FileManagement.Reader
  alias Portfolio.Content

  defstruct [:watcher_pid]

  @type t :: %__MODULE__{
          watcher_pid: pid()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec init(keyword()) :: {:ok, t()}
  def init(opts) do
    Logger.debug("Watcher init opts: #{inspect(opts)}")
    paths = Keyword.get(opts, :paths, [])
    {:ok, watcher_pid} = FileSystem.start_link(dirs: paths)
    FileSystem.subscribe(watcher_pid)
    {:ok, %__MODULE__{watcher_pid: watcher_pid}}
  end

  @spec handle_info(tuple(), t()) :: {:noreply, t()}
  def handle_info(
        {:file_event, watcher_pid, {path, events}},
        %{watcher_pid: watcher_pid} = state
      ) do
    Logger.info("File event detected: #{path}, events: #{inspect(events)}")

    Logger.info(
      "Is relevant file change? #{relevant_file_change?(path, events)}"
    )

    if relevant_file_change?(path, events) do
      Logger.info("Processing file change for: #{path}")
      process_file_change(path)
    end

    {:noreply, state}
  end

  @spec relevant_file_change?(String.t(), list()) :: boolean()
  defp relevant_file_change?(path, events) do
    Path.extname(path) == ".md" and
      not String.starts_with?(Path.basename(path), ".") and
      (:modified in events or :created in events)
  end

  @spec process_file_change(String.t()) :: :ok
  defp process_file_change(path) do
    case Reader.read_markdown_file(path) do
      {:ok, content_type, attrs} ->
        case Content.upsert_from_file(content_type, attrs) do
          {:ok, _content} ->
            Logger.info("Successfully upserted content from file: #{path}")

          {:error, reason} ->
            Logger.error(
              "Error upserting content from file #{path}: #{inspect(reason)}"
            )
        end

      {:error, reason} ->
        Logger.error("Error processing file #{path}: #{inspect(reason)}")
    end

    :ok
  end
end
