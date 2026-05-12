defmodule Portfolio.Content.PublicationControl.Scope do
  @moduledoc """
  Capability scope for operator-controlled content publication actions.
  """

  @enforce_keys [:actor]
  defstruct [:actor]

  @type t :: %__MODULE__{
          actor: String.t()
        }

  @doc """
  Builds a system operator scope for release and maintenance commands.
  """
  @spec system() :: t()
  def system do
    %__MODULE__{actor: "system"}
  end

  @doc """
  Builds an operator scope for a named command or actor.
  """
  @spec operator(String.t()) :: t()
  def operator(actor) when is_binary(actor) do
    %__MODULE__{actor: actor}
  end
end
