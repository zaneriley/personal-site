defmodule PortfolioWeb.ThemeChannel do
  @moduledoc """
  A Phoenix channel for managing the theme of the application.

  The channel allows users to toggle between light and dark themes.
  It also broadcasts the current theme to all connected clients.
  """
  use Phoenix.Channel
  require Logger

  def join("theme:lobby", _payload, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def join("user_theme:" <> user_id, _payload, socket) do
    if socket.assigns.user_id == String.to_integer(user_id) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    user_id = socket.assigns.user_id
    current_theme = LightDarkMode.GenServer.get_theme(user_id)
    broadcast!(socket, "theme_changed", %{theme: Atom.to_string(current_theme)})
    {:noreply, socket}
  end

  def handle_in("toggle_theme", %{"theme" => theme}, socket) do
    user_id = socket.assigns.user_id
    LightDarkMode.GenServer.toggle_theme(user_id)
    broadcast_user_theme(user_id, theme)
    {:noreply, socket}
  end

  defp broadcast_user_theme(user_id, theme) do
    broadcast!("user_theme:#{user_id}", "theme_changed", %{theme: theme})
  end
end
