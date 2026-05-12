defmodule Mix.Tasks.Portfolio.Content.Rollback do
  @moduledoc """
  Rolls live content back to a previous publication generation.
  """

  use Mix.Task

  alias Portfolio.Content.Publishing
  alias Portfolio.Content.PublicationControl.Output
  alias Portfolio.Content.PublicationControl.Scope

  @shortdoc "Roll back live content to a known-good generation"

  @impl Mix.Task
  @spec run([String.t()]) :: :ok | no_return()
  def run(args) do
    Mix.Task.run("app.start")

    with {:ok, target, opts} <- parse_args(args),
         {:ok, result} <- Publishing.rollback(Scope.system(), target, opts) do
      print_success(result, Keyword.get(opts, :json, false))

      :ok
    else
      {:error, reason} ->
        print_error(reason, json?(args))
        exit({:shutdown, 1})
    end
  end

  defp parse_args(args) do
    case OptionParser.parse(args, strict: [json: :boolean, reason: :string]) do
      {opts, [target], []} ->
        {:ok, target, normalize_opts(opts)}

      {_opts, _targets, _invalid} ->
        {:error, {:usage, usage()}}
    end
  end

  defp normalize_opts(opts) do
    opts
    |> Keyword.put_new(:reason, "Operator requested content rollback")
    |> Keyword.put_new(:json, false)
  end

  defp print_success(result, true) do
    Mix.shell().info(Jason.encode!(Output.success_json(result)))
  end

  defp print_success(result, false) do
    Mix.shell().info(Output.success_text(result))
  end

  defp print_error(reason, true) do
    Mix.shell().info(Jason.encode!(Output.error_json(reason)))
  end

  defp print_error(reason, false) do
    Mix.shell().info(Output.error_text(reason))
  end

  defp json?(args), do: "--json" in args

  defp usage do
    "Usage: mix portfolio.content.rollback [--json] [--reason REASON] TARGET"
  end
end
