defmodule PortfolioWeb.ContentPublicationController do
  @moduledoc false

  use PortfolioWeb, :controller

  alias Portfolio.Content
  alias Portfolio.Content.Schemas.PublicationLedgerEntry
  alias PortfolioWeb.ContentPublicationDebugLink

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => id, "token" => token}) do
    with :ok <- ContentPublicationDebugLink.verify(id, token),
         %PublicationLedgerEntry{} = entry <- Content.get_publication_event(id) do
      conn
      |> put_resp_header("cache-control", "private, no-store")
      |> put_resp_header("x-robots-tag", "noindex, nofollow, noarchive")
      |> put_root_layout(false)
      |> put_layout(false)
      |> render(:show, entry: entry)
    else
      _reason -> not_found(conn)
    end
  end

  def show(conn, _params), do: not_found(conn)

  defp not_found(conn) do
    send_resp(conn, :not_found, "not found")
  end
end
