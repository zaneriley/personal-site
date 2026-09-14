defmodule PortfolioWeb.Components.WeatherTest do
  use PortfolioWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias PortfolioWeb.Components.Weather

  describe "temperature/1" do
    test "renders signed, three-digit Celsius and Fahrenheit marks without JS" do
      for {temp, unit, label} <- [
            {24.0, "C", "24°C"},
            {40.0, "F", "104°F"},
            {-40.0, "F", "-40°F"},
            {-0.1, "C", "0°C"}
          ] do
        html =
          render_component(&Weather.temperature/1,
            temperature_c: temp,
            unit: unit
          )

        assert html =~ ~s(aria-label="#{label}")
        assert html =~ "rotate("
        assert html =~ ~s(r="0.119)
        assert html =~ "margin-left:-0.035em"
      end
    end
  end

  describe "weather/1" do
    test "missing reading has no fake temperature, sunny icon or live announcement" do
      html =
        render_component(&Weather.weather/1,
          snapshot: %{reading: nil, freshness: :unavailable}
        )

      assert html =~ "Weather unavailable"
      refute html =~ "weather-temperature"
      refute html =~ "<img"
      refute html =~ "aria-live"
    end

    test "known weather embeds the optimized artwork without another image request" do
      reading = %{
        temperature_c: 24.0,
        condition: :partly_cloudy,
        daylight?: false,
        reported_at: ~U[2026-09-13 03:00:00Z]
      }

      html =
        render_component(&Weather.weather/1,
          snapshot: %{reading: reading, freshness: :fresh}
        )

      tree = Floki.parse_fragment!(html)
      assert [_] = Floki.find(tree, ".weather-icon-slot[aria-hidden=true] svg")
      assert Floki.find(tree, "img") == []

      assert [_] =
               Floki.find(
                 tree,
                 "p.weather-heading.font-gt-flexa-mono.text-2xs > .optical-adjustment"
               )

      assert html =~ "Partly cloudy"
      assert Floki.find(tree, "details") == []
      assert Floki.text(Floki.find(tree, ".sr-only")) =~ "Partly cloudy"
      assert Floki.text(Floki.find(tree, "a.weather-credit")) == "WeatherAPI"
    end

    test "missing artwork retains the specific condition and report time" do
      reading = %{
        temperature_c: -2.0,
        condition: :freezing_fog,
        daylight?: false,
        reported_at: ~U[2026-09-13 03:00:00Z]
      }

      html =
        render_component(&Weather.weather/1,
          snapshot: %{reading: reading, freshness: :stale}
        )

      assert html =~ "Freezing fog"
      assert html =~ "Earlier report"
      assert html =~ "12:00"
      refute html =~ "<img"
    end
  end

  test "Japanese uses translated conditions while keeping the Cheee numeral mark" do
    Gettext.put_locale(PortfolioWeb.Gettext, "ja")

    reading = %{
      temperature_c: 24.0,
      condition: :rain,
      daylight?: false,
      reported_at: ~U[2026-09-13 03:00:00Z]
    }

    html =
      render_component(&Weather.weather/1,
        snapshot: %{reading: reading, freshness: :fresh}
      )

    assert html =~ "東京"
    assert html =~ "雨"
    assert html =~ "観測時刻"
    assert html =~ "font-cheee"
  end

  test "root layout embeds exactly one weather view without duplicating the page",
       %{conn: conn} do
    html = conn |> get("/en") |> html_response(200)
    tree = Floki.parse_document!(html)
    assert [_, _] = Floki.find(tree, "[data-phx-session]")
    assert [_] = Floki.find(tree, "#tokyo-weather")
    assert [_] = Floki.find(tree, "main")
  end

  test "embedded subscriber responds without HTTP or route metadata", %{
    conn: conn
  } do
    {:ok, view, html} =
      live_isolated(conn, PortfolioWeb.WeatherLive,
        session: %{"user_locale" => "en"}
      )

    assert html =~ "Tokyo"
    send(view.pid, :weather_changed)
    assert render(view) =~ "weather-mark"
    assert render_hook(view, "weather:resume", %{}) =~ "weather-mark"
  end
end
