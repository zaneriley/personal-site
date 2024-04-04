defmodule PortfolioWeb.UserSocketTest do
  use PortfolioWeb.ChannelCase
  @salt Application.compile_env(:portfolio, PortfolioWeb.Endpoint)[:token_salt]

  describe "connect/3 with authentication" do
    test "authenticates and assigns user_id with valid token" do
      #
      user_id = 123
      salt = @salt
      token = Phoenix.Token.sign(PortfolioWeb.Endpoint, salt, user_id)
      params = %{"token" => token}

      {:ok, socket} =
        PortfolioWeb.UserSocket.connect(params, %Phoenix.Socket{}, %{})

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

  describe "connect/3 with expired token" do
    test "denies connection with expired token" do
      user_id = 123
      salt = @salt
      expired_token = Phoenix.Token.sign(PortfolioWeb.Endpoint, salt, user_id, signed_at: System.system_time(:second) - 86_400 * 2)
      params = %{"token" => expired_token}

      assert {:error, reason} = PortfolioWeb.UserSocket.connect(params, %Phoenix.Socket{}, %{})
      assert reason == %{reason: "invalid_token"}
    end
  end

  describe "connect/3 with invalid token" do
    test "denies connection with invalid token" do
      params = %{"token" => "invalid_token"}

      {:error, reason} =
        PortfolioWeb.UserSocket.connect(params, %Phoenix.Socket{}, %{})

      assert reason == %{reason: "invalid_token"}
    end
  end

  describe "dynamic channel subscription" do
    setup do
      # Generate a token for authentication
      user_id = 456
      salt = @salt
      token = Phoenix.Token.sign(PortfolioWeb.Endpoint, salt, user_id)
      params = %{"token" => token}

      {:ok, socket} = connect(PortfolioWeb.UserSocket, params, %{})

      {:ok, user_id: user_id, socket: socket}
    end

    test "allows authenticated users to subscribe to their user_theme channel",
         %{user_id: user_id, socket: socket} do
      {:ok, _, _socket} =
        subscribe_and_join(socket, "user_theme:#{user_id}", %{})

      assert_broadcast "theme_changed", %{:theme => _}
    end
  end
end
