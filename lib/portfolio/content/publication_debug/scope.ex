defmodule Portfolio.Content.PublicationDebug.Scope do
  @moduledoc """
  Capability scope for content-publication debug reads.
  """

  @enforce_keys [:publication_event_id]
  defstruct [:publication_event_id]

  @type t :: %__MODULE__{
          publication_event_id: Ecto.UUID.t()
        }

  @doc """
  Builds a scope authorized to inspect one publication ledger entry.
  """
  @spec for_publication_event(Ecto.UUID.t()) :: t()
  def for_publication_event(id) when is_binary(id) do
    %__MODULE__{publication_event_id: id}
  end
end
