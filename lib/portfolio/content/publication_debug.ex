defmodule Portfolio.Content.PublicationDebug do
  @moduledoc """
  Read boundary for signed content-publication debug views.
  """

  alias Portfolio.Content.PublicationDebug.Scope
  alias Portfolio.Content.Schemas.PublicationLedgerEntry
  alias Portfolio.Repo

  @doc """
  Fetches a publication ledger event authorized by the given scope.
  """
  @spec get_publication_event(Scope.t(), Ecto.UUID.t()) ::
          {:ok, PublicationLedgerEntry.t()} | {:error, :not_found}
  def get_publication_event(
        %Scope{publication_event_id: id},
        id
      )
      when is_binary(id) do
    case Repo.get_by(PublicationLedgerEntry, id: id) do
      %PublicationLedgerEntry{} = entry -> {:ok, entry}
      nil -> {:error, :not_found}
    end
  end
end
