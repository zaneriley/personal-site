defmodule LightDarkMode.GenServer do
  @moduledoc """
  A GenServer for managing the theme of the application on a per-user basis.

  The GenServer keeps track of the current theme and provides functions for toggling between light and dark themes.

  # Usage

  To use the GenServer, start it in your application's supervision tree:

      children = [
        {Portfolio.LightDarkMode, []}
      ]

  Then, in your Phoenix controllers or views, you can use the `get_theme/1` and `toggle_theme/1` functions to get and toggle the current theme:

      current_theme = LightDarkMode.get_theme(user_id)
      LightDarkMode.toggle_theme(user_id)

  The `get_theme/1` function returns the current theme as an atom (`:light` or `:dark`), and the `toggle_theme/1` function toggles the theme between `:light` and `:dark`.

  """
  use GenServer
  require Logger

  # Start the GenServer with an empty map as the initial state
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Initial state setup with an empty map
  def init(_initial_args) do
    Logger.debug("Initializing theme state with an empty map")
    {:ok, %{}}
  end

  # Handling requests to get the current theme for a specific user
  def handle_call({:get_theme, user_id}, _from, state) do
    theme = Map.get(state, user_id, :light) # Default to :light if not set
    Logger.debug("Getting theme for user #{user_id}: #{theme}")
    {:reply, theme, state}
  end

  # Toggling the theme for a specific user
  def handle_cast({:toggle, user_id}, state) do
    current_theme = Map.get(state, user_id, :light)
    new_theme = switch_theme(current_theme)
    new_state = Map.put(state, user_id, new_theme)
    Logger.info("Theme toggled for user #{user_id} to #{new_theme}")
    {:noreply, new_state}
  end

  # Public API to get the current theme for a specific user
  def get_theme(user_id) do
    GenServer.call(__MODULE__, {:get_theme, user_id})
  end

  # Public API to toggle the theme for a specific user
  def toggle_theme(user_id) do
    GenServer.cast(__MODULE__, {:toggle, user_id})
  end

  # Helper function to toggle the theme
  defp switch_theme(:light), do: :dark
  defp switch_theme(:dark), do: :light
end
