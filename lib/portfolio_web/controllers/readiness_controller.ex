defmodule PortfolioWeb.ReadinessController do
  @moduledoc false

  use PortfolioWeb, :controller

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    Ecto.Adapters.SQL.query!(Portfolio.Repo, "SELECT 1")

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:ok, "ok")
  end
end
