defmodule LightDarkMode.GenServer do
  use GenServer

  require Logger

  def start_link(initial_theme) do
    GenServer.start_link(__MODULE__, initial_theme, name: __MODULE__)
  end

  # Define the initial state of the GenServer
  def init(initial_theme) do
    Logger.debug("Initializing theme state: #{initial_theme}")
    {:ok, initial_theme}
  end

  def handle_call(:get_theme, _from, state) do
    Logger.debug("Received :get_theme call, current theme: #{state}")
    {:reply, state, state}
  end

  def handle_cast({:toggle, current_theme}, state) do
    Logger.info("Toggling theme from #{current_theme}")
    new_state = toggle_theme(current_theme)
    Logger.debug("New theme state: #{new_state}")
    {:noreply, new_state}
  end

  def handle_cast({:system_preference_changed, preference}, state) do
    Logger.info("System preference changed to #{preference}")
    new_state = case preference do
      :light -> :light
      :dark -> :dark
      _ -> state
    end
    {:noreply, new_state}
  end

  # Optional: Handle storage errors and clear preference
  # These can be implemented based on specific requirements

  # Helper function to toggle the theme
  defp toggle_theme(:light), do: :dark
  defp toggle_theme(:dark), do: :light
  defp toggle_theme(_), do: :light  # Default to light if state is :system or undefined
end
