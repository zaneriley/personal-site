defmodule Portfolio.Weather.WeatherAPITest do
  use ExUnit.Case, async: true
  alias Portfolio.Weather.WeatherAPI

  @now ~U[2026-09-13 03:00:00Z]
  defp body(code, temp \\ 24.4) do
    %{
      "current" => %{
        "temp_c" => temp,
        "last_updated_epoch" => DateTime.to_unix(@now),
        "is_day" => 0,
        "condition" => %{"code" => code}
      }
    }
  end

  describe "decode/2" do
    test "preserves temperature when the condition code is unknown" do
      assert {:ok,
              %{temperature_c: 24.4, condition: :unknown, daylight?: false}} =
               WeatherAPI.decode(body(9999), @now)
    end

    test "keeps freezing and mixed precipitation distinct from rain and snow" do
      for {code, expected} <- [
            {1000, :clear},
            {1003, :partly_cloudy},
            {1183, :rain},
            {1213, :snow},
            {1147, :freezing_fog},
            {1198, :freezing_rain},
            {1204, :sleet},
            {1237, :ice_pellets},
            {1276, :thunderstorm},
            {1018, :dust}
          ] do
        assert {:ok, %{condition: ^expected}} =
                 WeatherAPI.decode(body(code), @now)
      end
    end

    test "rejects malformed, implausible, old and future observations" do
      for invalid <- [nil, %{}, body(1000, "24"), body(1000, 999)] do
        assert {:error, :invalid_reading} = WeatherAPI.decode(invalid, @now)
      end

      assert {:error, :invalid_reading} =
               WeatherAPI.decode(body(1000), DateTime.add(@now, 7201))

      assert {:error, :invalid_reading} =
               WeatherAPI.decode(body(1000), DateTime.add(@now, -301))
    end
  end

  describe "fetch/1" do
    test "missing credentials do not request or fabricate weather" do
      assert {:error, :not_configured} = WeatherAPI.fetch(key: nil)
    end

    test "decodes the HTTP boundary and sanitizes provider errors" do
      Req.Test.stub(__MODULE__, fn conn ->
        assert conn.host == "api.weatherapi.com"
        assert conn.query_string =~ "q=Tokyo"

        Req.Test.json(
          conn,
          put_in(
            body(1003),
            ["current", "last_updated_epoch"],
            System.os_time(:second)
          )
        )
      end)

      opts = [key: "test-only", request_options: [plug: {Req.Test, __MODULE__}]]
      assert {:ok, %{condition: :partly_cloudy}} = WeatherAPI.fetch(opts)

      Req.Test.stub(__MODULE__, fn conn ->
        Plug.Conn.send_resp(conn, 403, "secret detail")
      end)

      assert {:error, :provider_unavailable} = WeatherAPI.fetch(opts)
    end
  end
end
