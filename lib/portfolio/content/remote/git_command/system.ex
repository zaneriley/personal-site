defmodule Portfolio.Content.Remote.GitCommand.System do
  @moduledoc """
  Production `git` command runner backed by `System.cmd/3`.
  """

  @behaviour Portfolio.Content.Remote.GitCommand

  @impl true
  @spec run(String.t(), [String.t()], keyword()) ::
          {String.t(), non_neg_integer()}
  def run(executable, args, opts) do
    System.cmd(executable, args, opts)
  end
end
