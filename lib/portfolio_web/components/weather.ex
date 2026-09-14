defmodule PortfolioWeb.Components.Weather do
  @moduledoc "Tokyo weather artwork and the server-composed Cheee temperature mark."
  use PortfolioWeb, :html

  @external_resource "assets/weather-temperature-optics.json"
  @optics @external_resource |> File.read!() |> Jason.decode!()

  # Inline one optimized, trusted repository asset: weather adds no image request.
  for name <-
        ~w(sun moon partly-cloudy-day partly-cloudy-night cloudy rain snow thunderstorm) do
    path = "assets/static/images/weather/#{name}.svg"
    @external_resource path
    defp artwork(unquote(name)), do: unquote(File.read!(path))
  end

  attr :snapshot, :map, required: true
  attr :id, :string, default: "tokyo-weather"

  @spec weather(map()) :: Phoenix.LiveView.Rendered.t()
  def weather(assigns) do
    reading = assigns.snapshot.reading

    assigns =
      assigns
      |> assign(:reading, reading)
      |> assign(:icon, reading && icon(reading.condition, reading.daylight?))
      |> assign(:condition, reading && condition_label(reading.condition))
      |> assign(
        :reported,
        reading &&
          DateTime.shift_zone!(
            reading.reported_at,
            "Asia/Tokyo",
            Tzdata.TimeZoneDatabase
          )
      )

    ~H"""
    <div
      id={@id}
      class="footer-weather"
      phx-hook="Weather"
      data-freshness={@snapshot.freshness}
    >
      <.typography
        tag="p"
        font="mono"
        size="2xs"
        class="footer-eyebrow weather-heading"
      >
        {gettext("Tokyo")}
      </.typography>
      <div class="weather-mark">
        <span class="weather-icon-slot" aria-hidden="true">
          <%= if @icon do %>
            {raw(artwork(@icon))}
          <% end %>
        </span>
        <.temperature :if={@reading} temperature_c={@reading.temperature_c} />
        <span :if={!@reading} class="weather-unavailable">{gettext(
          "Weather unavailable"
        )}</span>
      </div>
      <.typography :if={@reading} tag="p" class="sr-only">
        {@condition}
        {if @snapshot.freshness == :stale,
          do: gettext("Earlier report"),
          else: gettext("Reported")}
        <time datetime={DateTime.to_iso8601(@reported)}>{Calendar.strftime(
          @reported,
          "%H:%M"
        )}</time>
        JST
      </.typography>
      <a :if={@reading} class="weather-credit" href="https://www.weatherapi.com/">WeatherAPI</a>
    </div>
    """
  end

  attr :temperature_c, :float, required: true
  attr :unit, :string, default: "C", values: ["C", "F"]

  @spec temperature(map()) :: Phoenix.LiveView.Rendered.t()
  def temperature(assigns) do
    value =
      if assigns.unit == "F",
        do: assigns.temperature_c * 9 / 5 + 32,
        else: assigns.temperature_c

    value = round(value)
    digits = Integer.digits(abs(value))
    poses = compose(digits)
    last = List.last(poses)

    assigns =
      assigns
      |> assign(:value, value)
      |> assign(:poses, poses)
      |> assign(:degree_y, -0.60 + @optics["degreeYEm"] + last.dy * 0.5)
      |> assign(:degree_x, 0.15 + @optics["degreeXEm"])
      |> assign(:degree_radius, 0.085 * @optics["degreeScale"])
      |> assign(:degree_stroke, 0.055 * @optics["degreeStrokeScale"])
      |> assign(
        :unit_style,
        "margin-left:#{@optics["unitGapEm"]}em;transform:translateY(#{last.dy * 0.5}em)"
      )

    ~H"""
    <span
      class="weather-temperature font-cheee"
      role="img"
      aria-label={"#{@value}°#{@unit}"}
      data-value={"#{@value}#{@unit}"}
    >
      <span class="weather-digits" aria-hidden="true">
        <svg
          :if={@value < 0}
          class="weather-minus"
          viewBox="0 -1 0.42 1"
          focusable="false"
        ><path d="M0 -0.34H0.32" stroke="currentColor" stroke-width="0.095" /></svg>
        <span
          :for={pose <- @poses}
          :key={pose.place}
          class="weather-digit"
          data-place={pose.place}
          data-digit={pose.digit}
          style={pose.style}
        >{pose.digit}</span>
      </span>
      <span class="weather-suffix" aria-hidden="true">
        <svg class="weather-degree" viewBox="0 -1 0.30 1" focusable="false"><circle
          cx={@degree_x}
          cy={@degree_y}
          r={@degree_radius}
          fill="none"
          stroke="currentColor"
          stroke-width={@degree_stroke}
        /></svg><span class="weather-unit-slot" style={@unit_style}><span class="weather-unit">{@unit}</span></span>
      </span>
    </span>
    """
  end

  defp compose(digits) do
    count = length(digits)

    {poses, _} =
      digits
      |> Enum.with_index()
      |> Enum.map_reduce({nil, 0, nil}, fn {digit, index},
                                           {previous, repeated, previous_pose} ->
        place = count - index - 1
        repeated = if digit == previous, do: repeated + 1, else: 0
        factor = if count >= 3, do: 0.9, else: 1

        direction = if rem(place, 2) == 1, do: -1, else: 1
        rotation = rotation(digit, place, count, direction, factor)
        dy = vertical_offset(digit, place, count, direction, factor)
        gap = digit_gap(previous_pose, previous, digit, rotation)

        scale = 1 - 0.025 * repeated

        pose = %{
          digit: digit,
          place: place,
          rotation: rotation,
          dy: dy,
          style:
            "margin-left:#{gap}em;transform:translateY(#{dy}em) rotate(#{rotation}deg) scale(#{scale})"
        }

        {pose, {digit, repeated, pose}}
      end)

    poses
  end

  defp rotation(_digit, _place, 1, _direction, _factor), do: -8

  defp rotation(digit, place, _count, direction, factor) do
    envelope = Map.get(%{0 => 0.6, 1 => 1}, place, 0.85)
    shape = Map.get(%{1 => 0.75, 8 => 0.9}, digit, 1)
    direction * 12 * factor * envelope * shape
  end

  defp vertical_offset(_digit, _place, 1, _direction, _factor), do: 0.015

  defp vertical_offset(digit, place, _count, direction, factor) do
    -direction * 0.07 * factor * if(place == 0, do: 0.65, else: 1) +
      if(digit in [0, 6, 8, 9], do: -0.012, else: 0)
  end

  defp digit_gap(nil, _previous, _digit, _rotation), do: 0

  defp digit_gap(previous_pose, previous, digit, rotation) do
    0.02 + if(previous == 1 or digit == 1, do: -0.04, else: 0) +
      if(previous == 7, do: -0.03, else: 0) +
      if(previous == 8 or digit == 8, do: 0.02, else: 0) +
      if previous_pose.rotation > rotation, do: -0.025, else: 0.012
  end

  defp icon(:clear, true), do: "sun"
  defp icon(:clear, false), do: "moon"
  defp icon(:partly_cloudy, true), do: "partly-cloudy-day"
  defp icon(:partly_cloudy, false), do: "partly-cloudy-night"

  defp icon(condition, _)
       when condition in [:cloudy, :rain, :snow, :thunderstorm],
       do: Atom.to_string(condition)

  defp icon(_, _), do: nil

  defp condition_label(:clear), do: gettext("Clear")
  defp condition_label(:partly_cloudy), do: gettext("Partly cloudy")
  defp condition_label(:cloudy), do: gettext("Cloudy")
  defp condition_label(:rain), do: gettext("Rain")
  defp condition_label(:snow), do: gettext("Snow")
  defp condition_label(:thunderstorm), do: gettext("Thunderstorms")
  defp condition_label(:mist), do: gettext("Mist")
  defp condition_label(:fog), do: gettext("Fog")
  defp condition_label(:freezing_fog), do: gettext("Freezing fog")
  defp condition_label(:freezing_rain), do: gettext("Freezing rain")
  defp condition_label(:sleet), do: gettext("Sleet")
  defp condition_label(:ice_pellets), do: gettext("Ice pellets")
  defp condition_label(:haze), do: gettext("Haze")
  defp condition_label(:dust), do: gettext("Dust")
  defp condition_label(:smoke), do: gettext("Smoke")
  defp condition_label(:smog), do: gettext("Smog")
  defp condition_label(_), do: gettext("Conditions unavailable")
end
