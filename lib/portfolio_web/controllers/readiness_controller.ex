defmodule PortfolioWeb.ReadinessController do
  @moduledoc false

  use PortfolioWeb, :controller

  alias Portfolio.Content

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    Ecto.Adapters.SQL.query!(Portfolio.Repo, "SELECT 1")

    if Content.content_ready?() do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(:ok, "ok")
    else
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(:service_unavailable, "content not ready")
    end
  end
end
