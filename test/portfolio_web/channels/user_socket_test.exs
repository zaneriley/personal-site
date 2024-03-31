defmodule PortfolioWeb.UserSocketTest do
  use PortfolioWeb.ChannelCase
  @salt Application.compile_env(:portfolio, PortfolioWeb.Endpoint)[:token_salt]

  describe "connect/3 with authentication" do
    test "authenticates and assigns user_id with valid token" do
      # Setup
      user_id = 123
      salt = @salt
      token = Phoenix.Token.sign(PortfolioWeb.Endpoint, salt, user_id)
      params = %{"token" => token}

      {:ok, socket} =
        PortfolioWeb.UserSocket.connect(params, %Phoenix.Socket{}, %{})

      # Verify
      assert socket.assigns.user_id == user_id
    end
  end

  describe "connect/3 without authentication" do
    test "allows connection without a token" do
      params = %{}

      {:ok, socket} =
        PortfolioWeb.UserSocket.connect(params, %Phoenix.Socket{}, %{})

      assert Map.has_key?(socket.assigns, :user_id) == false
    end
  end

  # describe "connect/3 with invalid token" do
  #   test "denies connection with invalid token" do
  #     # Setup
  #     params = %{"token" => "invalid_token"}

  #     # Exercise
  #     {:error, reason} = PortfolioWeb.UserSocket.connect(params, %Phoenix.Socket{}, %{})

  #     # Verify
  #     assert reason == %{reason: "invalid_token"}
  #   end
  # end

  # describe "dynamic channel subscription" do
  #   setup do
  #     user_id = 456
  #     salt = Application.compile_env(:portfolio, PortfolioWeb.Endpoint)[:token_salt]
  #     token = Phoenix.Token.sign(PortfolioWeb.Endpoint, salt, to_string(user_id))
  #     params = %{"token" => token}
  #     {:ok, socket, _} = PortfolioWeb.UserSocket.connect(params, %Phoenix.Socket{}, %{})
  #     {:ok, user_id: user_id, socket: socket}
  #   end

  #   test "allows authenticated users to subscribe to their user_theme channel", %{user_id: user_id, socket: socket} do
  #     # Assuming the existence of a function to simulate channel subscription
  #     {:ok, _, _} = simulate_subscribe_and_join(socket, "user_theme:#{user_id}")
  #     assert_received {:after_join}
  #   end
  # end
end
