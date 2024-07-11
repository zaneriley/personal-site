defmodule Credo.Check.AvoidMixEnv do
  @moduledoc """
  Credo check to avoid using Mix.env() in the codebase.
  """
  use Credo.Check, base_priority: :high

  @explanation [check: "Avoid using Mix.env() in the codebase."]

  @impl true
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
    |> Enum.reject(&is_nil/1)
  end

  defp traverse({:., _, [{:__aliases__, _, [:Mix]}, :env]}, meta, issue_meta) do
    issue = issue_for(issue_meta, meta[:line])
    {nil, [issue]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message:
        "Avoid using Mix.env() in the codebase. Mix.env() is not available in release mode. Use Application.get_env(:portfolio, :environment) instead.",
      trigger: "Mix.env()",
      line_no: line_no
    )
  end
end
