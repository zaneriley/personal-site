defmodule Portfolio.Content.Remote.GitCommand.System do
  @moduledoc """
  Production `git` command runner backed by `System.cmd/3`.
  """

  @behaviour Portfolio.Content.Remote.GitCommand

  @default_timeout 120_000

  @impl true
  @spec run(String.t(), [String.t()], keyword()) ::
          {String.t(), non_neg_integer()}
  def run(executable, args, opts) do
    timeout = Keyword.get_lazy(opts, :timeout, &default_timeout/0)
    opts = Keyword.delete(opts, :timeout)

    run_with_timeout(executable, args, opts, timeout)
  end

  defp default_timeout do
    Application.get_env(:portfolio, :git_command_timeout, @default_timeout)
  end

  defp run_with_timeout(executable, args, opts, timeout)
       when is_integer(timeout) do
    case timeout_executable() do
      nil ->
        {"GNU timeout is required for bounded git commands but was not found",
         124}

      timeout_path ->
        seconds = timeout |> milliseconds_to_seconds() |> Integer.to_string()

        System.cmd(
          timeout_path,
          ["--kill-after=5s", "#{seconds}s", executable | args],
          opts
        )
    end
  end

  defp timeout_executable do
    System.find_executable("timeout") || System.find_executable("gtimeout")
  end

  defp milliseconds_to_seconds(milliseconds) do
    max(1, div(milliseconds + 999, 1000))
  end
end
