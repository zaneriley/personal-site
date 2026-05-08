defmodule Portfolio.Content.FileManagement.Watcher do
  @moduledoc """
  Monitors file system changes for markdown content files.

  Uses FileSystem to watch specified directories, processes relevant file events,
  and triggers content updates through the content promoter.
  """

  use GenServer
  require Logger
  alias Portfolio.Content.FileManagement.Promoter

  defstruct [:watcher_pid]

  @type t :: %__MODULE__{
          watcher_pid: pid()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    Logger.info("Attempting to start Watcher with opts: #{inspect(opts)}")
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
      promote_file_change(path)
    end

    {:noreply, state}
  end

  @spec relevant_file_change?(String.t(), list()) :: boolean()
  defp relevant_file_change?(path, events) do
    not hidden_path?(path) and
      Path.extname(path) == ".md" and
      (:modified in events or :created in events or :deleted in events)
  end

  defp hidden_path?(path) do
    path
    |> Path.split()
    |> Enum.any?(fn part -> String.starts_with?(part, ".") end)
  end

  @spec promote_file_change(String.t()) :: :ok
  defp promote_file_change(path) do
    case Promoter.promote_path(path) do
      {:ok, result} ->
        Logger.info("Promoted content file #{path}: #{inspect(result)}")

      {:error, result} ->
        Logger.error(
          "Failed to promote content file #{path}: #{inspect(result)}"
        )
    end

    :ok
  end
end
