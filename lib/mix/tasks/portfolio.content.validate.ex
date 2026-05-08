defmodule Mix.Tasks.Portfolio.Content.Validate do
  @moduledoc """
  Validates a checked-out portfolio content repository.

  This task is intended for content-repo CI. It exercises the same promotion
  path production uses, but rolls back the transaction so validation does not
  publish or mutate persistent content state.
  """

  use Mix.Task

  alias Portfolio.Content.FileManagement.Validator

  @shortdoc "Validate publishable portfolio content"

  @impl Mix.Task
  @spec run([String.t()]) :: :ok | no_return()
  def run([content_path]) do
    Mix.Task.run("app.start")

    content_path = Path.expand(content_path)

    case Validator.validate_all(content_path) do
      {:ok, result} ->
        Mix.shell().info(success_message(content_path, result))

      {:error, result} ->
        Mix.shell().error(failure_message(content_path, result))
        exit({:shutdown, 1})
    end
  end

  def run(_args) do
    Mix.raise("Usage: mix portfolio.content.validate CONTENT_PATH")
  end

  defp success_message(content_path, result) do
    """
    Content validation passed for #{content_path}
    Promotable files: #{length(result.promoted)}
    Removed entries if published: #{length(result.removed)}
    Skipped paths: #{length(result.skipped)}
    """
  end

  defp failure_message(content_path, result) do
    errors =
      result.errors
      |> Enum.reverse()
      |> Enum.map_join("\n", &format_error(content_path, &1))

    """
    Content validation failed for #{content_path}
    Errors:
    #{errors}
    """
  end

  defp format_error(content_path, %{path: path, reason: reason}) do
    display_path = Path.relative_to(path, content_path)
    "- #{display_path}: #{inspect(reason)}"
  end
end
