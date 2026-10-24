defmodule Portfolio.WeatherTest do
  use ExUnit.Case, async: true
  alias Portfolio.Weather

  describe "snapshot/2" do
    test "freshness follows the observation, never the most recent fetch" do
      now = ~U[2026-09-13 03:00:00Z]
      reading = %{reported_at: now, fetched_at: DateTime.add(now, 7000)}

      assert %{freshness: :fresh} =
               Weather.snapshot(reading, DateTime.add(now, 1800))

      assert %{freshness: :stale, reading: ^reading} =
               Weather.snapshot(reading, DateTime.add(now, 1801))

      assert %{freshness: :stale} =
               Weather.snapshot(reading, DateTime.add(now, 7200))

      assert %{freshness: :unavailable, reading: nil} =
               Weather.snapshot(reading, DateTime.add(now, 7201))

      assert %{freshness: :unavailable} = Weather.snapshot(nil, now)
    end
  end
end
