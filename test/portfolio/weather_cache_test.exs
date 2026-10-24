defmodule Portfolio.WeatherCacheTest do
  # Exercises the app's named ETS owner and PubSub topic.
  use ExUnit.Case, async: false
  alias Portfolio.Weather

  test "page reads remain available during a shared fetch; failures keep the last report" do
    :ok = Supervisor.terminate_child(Portfolio.Supervisor, Weather)
    on_exit(fn -> Supervisor.restart_child(Portfolio.Supervisor, Weather) end)
    parent = self()
    Weather.subscribe()

    server =
      start_supervised!(
        {Weather,
         fetch: fn ->
           send(parent, {:fetching, self()})

           receive do
             {:complete, result} -> result
           end
         end}
      )

    assert_receive {:fetching, worker}
    assert %{freshness: :unavailable} = Weather.current()
    now = DateTime.utc_now()

    reading = %{
      temperature_c: 24.0,
      condition: :clear,
      daylight?: true,
      reported_at: now,
      fetched_at: now,
      source: :weather_api
    }

    send(worker, {:complete, {:ok, reading}})
    assert_receive :weather_changed
    assert %{reading: ^reading, freshness: :fresh} = Weather.current()
    send(server, :refresh)
    assert_receive {:fetching, worker}
    assert %{reading: ^reading} = Weather.current()
    send(worker, {:complete, {:error, :provider_unavailable}})
    assert_receive :weather_changed
    assert %{reading: ^reading} = Weather.current()
  end
end
