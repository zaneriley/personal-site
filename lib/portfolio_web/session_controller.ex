defmodule PortfolioWeb.SessionController do
  use PortfolioWeb, :controller
  require Logger

  @salt Application.compile_env(:portfolio, PortfolioWeb.Endpoint)[:token_salt]

  def generate(conn, _params) do
    # we don't need real user_ids for our application,
    # but in the future we might want to convert these to real user auth
    user_id = :rand.uniform(1000000)
    salt = @salt
    token = Phoenix.Token.sign(PortfolioWeb.Endpoint, salt, user_id)
    Logger.info("New token generated for user_id: #{user_id}, token: #{token}")
    json(conn, %{token: token, user_id: user_id})
  end
end
