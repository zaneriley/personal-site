defmodule Portfolio.Content.Remote.GitCommand do
  @moduledoc """
  Boundary for invoking the external `git` executable.
  """

  @callback run(String.t(), [String.t()], keyword()) ::
              {String.t(), non_neg_integer()}
end
