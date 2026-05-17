defmodule PortfolioWeb.ContentPublicationDebugLink do
  @moduledoc """
  Builds and verifies signed links to private publication debug pages.
  """

  use PortfolioWeb, :verified_routes

  alias Portfolio.Content.PublicationDebug.Scope
  alias Portfolio.Content.Schemas.PublicationLedgerEntry
  alias PortfolioWeb.SiteOrigin

  @salt "content-publication-debug"

  @doc """
  Builds an absolute signed URL for a publication ledger entry.
  """
  @spec signed_url(PublicationLedgerEntry.t()) :: String.t()
  def signed_url(%PublicationLedgerEntry{id: id}) when is_binary(id) do
    token = Phoenix.Token.sign(PortfolioWeb.Endpoint, @salt, id)

    SiteOrigin.absolute_url(~p"/ops/content/publications/#{id}?token=#{token}")
  end

  @doc """
  Verifies that a token grants access to the requested publication entry.
  """
  @spec verify(String.t(), String.t()) :: {:ok, Scope.t()} | {:error, term()}
  def verify(id, token) when is_binary(id) and is_binary(token) do
    case Phoenix.Token.verify(PortfolioWeb.Endpoint, @salt, token,
           max_age: token_max_age_seconds()
         ) do
      {:ok, ^id} -> {:ok, Scope.for_publication_event(id)}
      {:ok, _other_id} -> {:error, :wrong_publication}
      {:error, reason} -> {:error, reason}
    end
  end

  defp token_max_age_seconds do
    Application.get_env(
      :portfolio,
      :publication_debug_token_max_age_seconds,
      2_592_000
    )
  end
end
