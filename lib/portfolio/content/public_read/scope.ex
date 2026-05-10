defmodule Portfolio.Content.PublicRead.Scope do
  @moduledoc """
  Capability scope for public, live content reads.

  Public visitors may only resolve content from the generation currently marked
  live. Threading the generation through this scope keeps alias lookups bound to
  the same read model as normal content pages.
  """

  alias Portfolio.Content.Publishing

  @enforce_keys [:publication_generation_id]
  defstruct [:publication_generation_id]

  @type t :: %__MODULE__{
          publication_generation_id: Ecto.UUID.t() | nil
        }

  @doc """
  Builds the scope for the currently live public content generation.
  """
  @spec current() :: t()
  def current do
    %__MODULE__{publication_generation_id: Publishing.live_generation_id()}
  end
end
