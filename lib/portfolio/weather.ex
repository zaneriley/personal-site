defmodule Portfolio.Weather do
  @moduledoc """
  One shared Tokyo observation. HTTP refreshes run outside page requests;
  readers use ETS directly, including while the provider is slow or restarting.
  Source age, rather than successful fetch time, determines freshness.
  """
  use GenServer

  alias Portfolio.Weather.WeatherAPI

  @topic "weather:tokyo"
  @interval :timer.minutes(15)

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Reads the last observation without performing network IO."
  @spec current(DateTime.t()) :: map()
  def current(now \\ DateTime.utc_now()) do
    reading =
      case :ets.whereis(__MODULE__) do
        :undefined ->
          nil

        table ->
          case :ets.lookup(table, :reading) do
            [{:reading, value}] -> value
            [] -> nil
          end
      end

    snapshot(reading, now)
  rescue
    ArgumentError -> snapshot(nil, now)
  end

  @doc "Classifies source age. Old readings are never relabelled as current."
  @spec snapshot(map() | nil, DateTime.t()) :: map()
  def snapshot(nil, _now), do: %{reading: nil, freshness: :unavailable}

  def snapshot(reading, now) do
    age = DateTime.diff(now, reading.reported_at)

    cond do
      age < -300 or age > 7_200 -> %{reading: nil, freshness: :unavailable}
      age > 1_800 -> %{reading: reading, freshness: :stale}
      true -> %{reading: reading, freshness: :fresh}
    end
  end

  @spec subscribe() :: :ok | {:error, term()}
  def subscribe, do: Phoenix.PubSub.subscribe(Portfolio.PubSub, @topic)

  @impl true
  @spec init(keyword()) :: {:ok, map()}
  def init(opts) do
    :ets.new(__MODULE__, [
      :named_table,
      :protected,
      :set,
      read_concurrency: true
    ])

    send(self(), :refresh)

    {:ok,
     %{
       fetch: Keyword.get(opts, :fetch, &WeatherAPI.fetch/0),
       task: nil,
       age_timer: nil
     }}
  end

  @impl true
  @spec handle_info(term(), map()) :: {:noreply, map()}
  def handle_info(:refresh, %{task: nil} = state) do
    Process.send_after(self(), :refresh, @interval)
    task = Task.Supervisor.async_nolink(Portfolio.WeatherTasks, state.fetch)
    {:noreply, %{state | task: task.ref}}
  end

  def handle_info(:refresh, state), do: {:noreply, state}

  def handle_info({ref, result}, %{task: ref} = state) do
    Process.demonitor(ref, [:flush])

    case result do
      {:ok, reading} -> :ets.insert(__MODULE__, {:reading, reading})
      {:error, _} -> :ok
    end

    notify()
    {:noreply, schedule_age(%{state | task: nil})}
  end

  def handle_info({:DOWN, ref, :process, _, _}, %{task: ref} = state) do
    {:noreply, %{state | task: nil}}
  end

  def handle_info(:age, state) do
    notify()
    {:noreply, schedule_age(%{state | age_timer: nil})}
  end

  defp notify,
    do: Phoenix.PubSub.broadcast(Portfolio.PubSub, @topic, :weather_changed)

  defp schedule_age(state) do
    if state.age_timer, do: Process.cancel_timer(state.age_timer)
    now = DateTime.utc_now()

    timer =
      case current(now) do
        %{reading: nil} ->
          nil

        %{reading: reading, freshness: freshness} ->
          boundary = if freshness == :fresh, do: 1_801, else: 7_201

          delay =
            max(
              1,
              boundary * 1_000 -
                DateTime.diff(now, reading.reported_at, :millisecond)
            )

          Process.send_after(self(), :age, delay)
      end

    %{state | age_timer: timer}
  end
end
