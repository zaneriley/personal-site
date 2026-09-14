defmodule PortfolioWeb.WeatherLive do
  @moduledoc "The layout-free footer subscriber; observations are shared across visitors."
  use PortfolioWeb, :live_view

  alias Portfolio.Weather

  @impl true
  @spec mount(term(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t(), keyword()}
  def mount(_params, session, socket) do
    locale = if session["user_locale"] == "ja", do: "ja", else: "en"
    Gettext.put_locale(PortfolioWeb.Gettext, locale)
    if connected?(socket), do: Weather.subscribe()
    {:ok, assign(socket, :snapshot, Weather.current()), layout: false}
  end

  @impl true
  @spec handle_info(:weather_changed, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(:weather_changed, socket) do
    {:noreply, assign(socket, :snapshot, Weather.current())}
  end

  @impl true
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("weather:resume", _, socket) do
    {:noreply, assign(socket, :snapshot, Weather.current())}
  end

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <PortfolioWeb.Components.Weather.weather snapshot={@snapshot} />
    """
  end
end
