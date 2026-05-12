defmodule Mix.Tasks.Portfolio.Content.Status do
  @moduledoc """
  Prints the current content publication status.
  """

  use Mix.Task

  alias Portfolio.Content.Publishing

  @shortdoc "Print content publication status"

  @impl Mix.Task
  @spec run([String.t()]) :: :ok | no_return()
  def run(args) do
    Mix.Task.run("app.start")

    status = Publishing.status()

    if "--json" in args do
      Mix.shell().info(Jason.encode!(status))
    else
      Mix.shell().info(Publishing.status_text())
    end

    if is_nil(status.live) do
      exit({:shutdown, 1})
    else
      :ok
    end
  end
end
