defmodule Portfolio.Weather.WeatherAPI do
  @moduledoc "WeatherAPI's current Tokyo observation, translated at the HTTP boundary."

  @rain [1063, 1150, 1153, 1180, 1183, 1186, 1189, 1192, 1195, 1240, 1243, 1246]
  @snow [1066, 1114, 1117, 1210, 1213, 1216, 1219, 1222, 1225, 1255, 1258]
  @freezing [1072, 1168, 1171, 1198, 1201]
  @sleet [1069, 1204, 1207, 1249, 1252]
  @ice [1237, 1261, 1264]
  @thunder [1087, 1273, 1276, 1279, 1282]
  @dust [1015, 1018, 1021, 1024, 1027, 1045, 1048]

  @doc "Fetches once; credentials and raw HTTP errors never leave this boundary."
  @spec fetch(keyword()) :: {:ok, map()} | {:error, atom()}
  def fetch(opts \\ []) do
    key =
      Keyword.get(opts, :key, Application.get_env(:portfolio, :weather_api_key))

    if is_binary(key) and key != "" do
      request = Keyword.get(opts, :request_options, [])

      case Req.get(
             Keyword.merge(request,
               url: "https://api.weatherapi.com/v1/current.json",
               params: [key: key, q: "Tokyo", aqi: "no"],
               retry: false,
               redirect: false,
               receive_timeout: 5_000,
               connect_options: [timeout: 3_000]
             )
           ) do
        {:ok, %{status: 200, body: body}} -> decode(body, DateTime.utc_now())
        _ -> {:error, :provider_unavailable}
      end
    else
      {:error, :not_configured}
    end
  end

  @doc "Validates the provider observation without accepting provider HTML or asset URLs."
  @spec decode(term(), DateTime.t()) ::
          {:ok, map()} | {:error, :invalid_reading}
  def decode(
        %{
          "current" => %{
            "temp_c" => temp,
            "last_updated_epoch" => epoch,
            "is_day" => day,
            "condition" => %{"code" => code}
          }
        },
        now
      )
      when is_number(temp) and temp >= -100 and temp <= 100 and
             is_integer(epoch) and
             day in [0, 1] and is_integer(code) do
    with {:ok, reported_at} <- DateTime.from_unix(epoch),
         age when age >= -300 and age <= 7_200 <-
           DateTime.diff(now, reported_at) do
      {:ok,
       %{
         temperature_c: temp,
         condition: condition(code),
         daylight?: day == 1,
         reported_at: reported_at,
         fetched_at: now,
         source: :weather_api
       }}
    else
      _ -> {:error, :invalid_reading}
    end
  end

  def decode(_, _), do: {:error, :invalid_reading}

  # https://www.weatherapi.com/docs/weather_conditions.json
  defp condition(1000), do: :clear
  defp condition(1003), do: :partly_cloudy
  defp condition(code) when code in [1006, 1009], do: :cloudy
  defp condition(1030), do: :mist
  defp condition(1135), do: :fog
  defp condition(1147), do: :freezing_fog
  defp condition(1012), do: :haze
  defp condition(code) when code in @dust, do: :dust
  defp condition(code) when code in [1033, 1036], do: :smoke
  defp condition(code) when code in [1039, 1042], do: :smog
  defp condition(code) when code in @rain, do: :rain
  defp condition(code) when code in @snow, do: :snow
  defp condition(code) when code in @freezing, do: :freezing_rain
  defp condition(code) when code in @sleet, do: :sleet
  defp condition(code) when code in @ice, do: :ice_pellets
  defp condition(code) when code in @thunder, do: :thunderstorm
  defp condition(_), do: :unknown
end
