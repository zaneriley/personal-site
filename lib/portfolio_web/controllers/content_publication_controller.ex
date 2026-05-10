defmodule PortfolioWeb.ContentPublicationController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html, :json]
  use PortfolioWeb, :verified_routes

  import Plug.Conn

  alias Portfolio.Content.PublicationDebug
  alias Portfolio.Content.Schemas.PublicationLedgerEntry
  alias PortfolioWeb.ContentPublicationDebugLink

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => id, "token" => token}) do
    with {:ok, scope} <- ContentPublicationDebugLink.verify(id, token),
         {:ok, %PublicationLedgerEntry{} = entry} <-
           PublicationDebug.get_publication_event(scope, id) do
      conn
      |> put_resp_header("cache-control", "private, no-store")
      |> put_resp_header("x-robots-tag", "noindex, nofollow, noarchive")
      |> assign(:current_path, ~p"/ops/content/publications/#{entry.id}")
      |> assign(:user_locale, "en")
      |> render(:show, entry: entry)
    else
      {:error, :expired} -> not_found(conn)
      {:error, :invalid} -> not_found(conn)
      {:error, :not_found} -> not_found(conn)
      {:error, :wrong_publication} -> not_found(conn)
    end
  end

  def show(conn, %{"id" => id}) when is_binary(id), do: not_found(conn)

  defp not_found(conn) do
    send_resp(conn, :not_found, "not found")
  end
end
