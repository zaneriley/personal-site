# defmodule PortfolioWeb.ThemeChannelTest do
#   use PortfolioWeb.ChannelCase

#   alias PortfolioWeb.UserSocket

#   setup do
#     user_id = 1
#     # Assuming you have a function to generate a token or you can directly use Phoenix.Token.sign/4 here
#     salt = Application.get_env(:portfolio, PortfolioWeb.Endpoint)[:token_salt]
#     token = Phoenix.Token.sign(PortfolioWeb.Endpoint, salt, to_string(user_id))

#     # Connect using the generated token
#     {:ok, socket, _} = connect(UserSocket, %{"token" => token})
#     {:ok, user_id: user_id, socket: socket}
#   end

#   describe "Joining Channels" do
#     test "users can join the theme:lobby channel and receive after_join message", %{socket: socket} do
#       {:ok, _, socket} = subscribe_and_join(socket, "theme:lobby", %{})
#       assert_received {:after_join}
#     end

#     test "users can join their specific theme channel with correct user ID", %{socket: socket} do
#       {:ok, _, socket} = subscribe_and_join(socket, "user_theme:1", %{})
#       assert_received {:after_join}
#     end

#     test "joining a user-specific theme channel with incorrect user ID returns unauthorized", %{socket: socket} do
#       {:error, reason} = subscribe_and_join(socket, "user_theme:2", %{})
#       assert reason == %{reason: "unauthorized"}
#     end
#   end

#   describe "Handling :after_join" do
#     test "broadcasts the current theme to the user after joining", %{socket: socket} do
#       PortfolioWeb.ThemeChannel.handle_info(:after_join, socket)
#       assert_broadcast "theme_changed", %{theme: _}
#     end
#   end

#   describe "Toggling Theme" do
#     test "toggles the theme and broadcasts the new theme to the user-specific channel", %{socket: socket} do
#       # Assuming the initial theme is :light
#       send(socket, {:handle_in, "toggle_theme", %{"theme" => "dark"}, socket})
#       assert_broadcast "theme_changed", %{theme: "dark"}
#     end
#   end
# end
