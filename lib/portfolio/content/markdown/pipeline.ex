defmodule Portfolio.Content.Markdown.Pipeline do
  @moduledoc """
  A pipeline for transforming Markdown AST through a series of stages.

  The pipeline processes an AST representation of markdown content through a
  configurable series of transform stages. Each stage can modify the AST
  before passing it to the next stage.
  """

  require Logger

  @doc """
  Process an AST through a series of transformation stages.

  Each stage in the pipeline receives the AST from the previous stage
  and returns a transformed AST. Any stage can halt the pipeline by
  returning an error tuple.

  ## Parameters

  * `ast` - The AST to process
  * `opts` - Options for the pipeline and stages, including:
      * `:stages` - List of stage modules to apply (required)
      * Other options are passed to each stage

  ## Returns

  * `{:ok, transformed_ast}` - The AST after all transforms are applied
  * `{:error, reason}` - If any stage returns an error

  ## Examples

      Pipeline.process(ast, stages: [
        Typography,
        Component,
        Layout
      ])
  """
  def process(ast, opts \\ []) do
    stages = Keyword.get(opts, :stages, [])

    if Enum.empty?(stages) do
      Logger.warning("Pipeline executed with no stages")
      {:ok, ast}
    else
      apply_stages(ast, stages, opts)
    end
  end

  # Private helpers

  defp apply_stages(ast, [], _opts), do: {:ok, ast}

  defp apply_stages(ast, [stage | remaining_stages], opts) do
    Logger.debug("Running pipeline stage: #{inspect(stage)}")

    case apply_stage(stage, ast, opts) do
      {:ok, transformed_ast} ->
        # Continue processing with the next stage
        apply_stages(transformed_ast, remaining_stages, opts)

      {:error, reason} = error ->
        # Stage returned an error, halt pipeline
        Logger.error(
          "Pipeline halted at stage #{inspect(stage)}: #{inspect(reason)}"
        )

        error
    end
  end

  defp apply_stage(stage, ast, opts) do
    # All stages should implement an apply/2 function
    apply(stage, :apply, [ast, opts])
  rescue
    error ->
      Logger.error(
        "Error in pipeline stage #{inspect(stage)}: #{inspect(error)}"
      )

      {:error, "Error in pipeline stage #{inspect(stage)}: #{inspect(error)}"}
  end
end
