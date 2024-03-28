defmodule PortfolioWeb.UserSocket do
  use Phoenix.Socket
  require Logger
  @salt Application.compile_env(:portfolio, PortfolioWeb.Endpoint)[:token_salt]

  ## Channels
  # channel "room:*", PortfolioWeb.RoomChannel
  channel "theme:lobby", PortfolioWeb.ThemeChannel
  # Add this line to handle dynamic user theme channels
  channel "user_theme:*", PortfolioWeb.ThemeChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    salt = @salt
    case Phoenix.Token.verify(socket, salt, token, max_age: 86400) do
      {:ok, user_id} ->
        Logger.debug("User connected with user_id: #{user_id}")
        {:ok, assign(socket, :user_id, user_id)}
      {:error, _reason} ->
        Logger.error("User connection failed due to invalid token")
        {:error, %{reason: "invalid_token"}}
    end
  end


  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     PortfolioWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
