defmodule Portfolio.ContentUpdater.Updater do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_args) do
    {:ok, %{}} # For now, an empty state
  end

  @impl true
  def handle_info({:file_change, path, locale}, state) do
    # In Phase 2, we'll implement the content update logic here
    {:noreply, state}
  end
end
