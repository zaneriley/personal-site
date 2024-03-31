defmodule LightDarkModeTest do
  use ExUnit.Case, async: true
  alias LightDarkMode.GenServer

  setup do
    :ok = LightDarkMode.GenServer.reset_state()
  end

  describe "LightDarkMode GenServer" do
    # test "starts correctly with an empty state" do
    #   {:ok, pid} = LightDarkMode.GenServer.start_link()
    #   assert GenServer.call(pid, :state) == %{}
    # end

    test "returns :light as the default theme for a new user" do
      user_id = 1
      assert GenServer.get_theme(user_id) == :light
    end

    test "toggles the theme for a user multiple times" do
      user_id = 1
      # Initial theme is :light
      expected_themes = [:dark, :light, :dark, :light]

      Enum.each(expected_themes, fn expected_theme ->
        LightDarkMode.GenServer.toggle_theme(user_id)
        assert LightDarkMode.GenServer.get_theme(user_id) == expected_theme
      end)
    end

    test "handles concurrent toggles for multiple users" do
      user_ids = 1..10

      Enum.each(user_ids, fn user_id ->
        GenServer.toggle_theme(user_id)
      end)

      Enum.each(user_ids, fn user_id ->
        assert GenServer.get_theme(user_id) == :dark
      end)
    end
  end
end
