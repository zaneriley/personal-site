defmodule Portfolio.Content.MarkdownRendering.Pipeline do
  @moduledoc """
  Implements a pipeline for transforming markdown content through a series of stages.

  The pipeline architecture allows for modular, composable transformations of markdown
  content, from parsing to AST manipulation to final rendering. Each stage in the
  pipeline is responsible for a specific transformation and can be composed with
  other stages to form a complete processing flow.
  """

  alias Portfolio.Content.MarkdownRendering.AST

  @typedoc "Result of a pipeline stage operation"
  @type result :: {:ok, AST.t()} | {:error, String.t()}

  @typedoc "A pipeline stage function that transforms AST"
  @type stage :: (AST.t() -> result())

  @doc """
  Creates a new pipeline with the given stages.

  ## Examples

      iex> alias Portfolio.Content.MarkdownRendering.Pipeline
      iex> pipeline = Pipeline.new([&Pipeline.identity/1])
      iex> is_function(pipeline, 1)
      true
  """
  @spec new([stage()]) :: (AST.t() -> result())
  def new(stages) when is_list(stages) do
    fn input -> execute_pipeline(stages, input) end
  end

  # Helper function to execute the pipeline stages
  @spec execute_pipeline([stage()], AST.t()) :: result()
  defp execute_pipeline(stages, input) do
    Enum.reduce_while(stages, {:ok, input}, fn stage, {:ok, ast} ->
      case stage.(ast) do
        {:ok, transformed_ast} ->
          {:cont, {:ok, transformed_ast}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  @doc """
  Adds a stage to an existing pipeline.

  ## Examples

      iex> alias Portfolio.Content.MarkdownRendering.Pipeline
      iex> pipeline = Pipeline.new([])
      iex> pipeline = Pipeline.add_stage(pipeline, &Pipeline.identity/1)
      iex> is_function(pipeline, 1)
      true
  """
  @spec add_stage((AST.t() -> result()), stage()) :: (AST.t() -> result())
  def add_stage(pipeline, stage)
      when is_function(pipeline, 1) and is_function(stage, 1) do
    fn input ->
      with {:ok, ast} <- pipeline.(input) do
        stage.(ast)
      end
    end
  end

  @doc """
  Processes an AST through a pipeline.

  ## Examples

      iex> alias Portfolio.Content.MarkdownRendering.{Pipeline, AST}
      iex> ast = [AST.text("Hello")]
      iex> pipeline = Pipeline.new([&Pipeline.identity/1])
      iex> Pipeline.process(pipeline, ast)
      {:ok, ["Hello"]}
  """
  @spec process((AST.t() -> result()), AST.t()) :: result()
  def process(pipeline, ast) when is_function(pipeline, 1) and is_list(ast) do
    pipeline.(ast)
  end

  @doc """
  An identity stage that returns the AST unchanged.
  Useful for testing and as a base for other stages.

  ## Examples

      iex> alias Portfolio.Content.MarkdownRendering.Pipeline
      iex> Pipeline.identity(["Hello"])
      {:ok, ["Hello"]}
  """
  @spec identity(AST.t()) :: result()
  def identity(ast) when is_list(ast), do: {:ok, ast}

  @doc """
  Creates a stage that applies a mapping function to every node in the AST.

  ## Examples

      iex> alias Portfolio.Content.MarkdownRendering.{Pipeline, AST}
      iex> ast = [{"p", %{}, ["Text"], %{}}]
      iex> mapper = fn
      ...>   {"p", attrs, content, meta} -> {"div", attrs, content, meta}
      ...>   node -> node
      ...> end
      iex> stage = Pipeline.map_stage(mapper)
      iex> stage.(ast)
      {:ok, [{"div", %{}, ["Text"], %{}}]}
  """
  @spec map_stage((AST.node() -> AST.node())) :: stage()
  def map_stage(mapper) when is_function(mapper, 1) do
    fn ast ->
      {:ok, AST.map(ast, mapper)}
    end
  end

  @doc """
  Creates a stage that filters the AST, keeping only nodes that match the predicate.
  This operates on the top level of the AST only.

  ## Examples

      iex> alias Portfolio.Content.MarkdownRendering.{Pipeline, AST}
      iex> ast = [{"p", %{}, ["Text"], %{}}, {"div", %{}, ["Ignored"], %{}}]
      iex> stage = Pipeline.filter_stage(fn
      ...>   {"p", _, _, _} -> true
      ...>   _ -> false
      ...> end)
      iex> stage.(ast)
      {:ok, [{"p", %{}, ["Text"], %{}}]}
  """
  @spec filter_stage((AST.node() -> boolean())) :: stage()
  def filter_stage(predicate) when is_function(predicate, 1) do
    fn ast ->
      {:ok, Enum.filter(ast, predicate)}
    end
  end

  @doc """
  Logs the current state of the AST and continues the pipeline.
  Useful for debugging pipeline execution.

  ## Examples

      iex> alias Portfolio.Content.MarkdownRendering.Pipeline
      iex> Pipeline.log_stage(["Hello"], "Test log")
      {:ok, ["Hello"]}
  """
  @spec log_stage(AST.t(), String.t()) :: result()
  def log_stage(ast, message \\ "Pipeline stage")
      when is_list(ast) and is_binary(message) do
    require Logger
    Logger.debug("#{message}: #{inspect(ast, pretty: true, limit: 5)}")
    {:ok, ast}
  end

  @doc """
  Wraps a function that might raise exceptions into a pipeline stage.
  This ensures the pipeline can handle errors gracefully.

  ## Examples

      iex> alias Portfolio.Content.MarkdownRendering.Pipeline
      iex> safe_fn = fn _ -> raise "Error" end
      iex> stage = Pipeline.wrap_safe(safe_fn)
      iex> {:error, reason} = stage.(["test"])
      iex> String.contains?(reason, "Error")
      true
  """
  @spec wrap_safe((AST.t() -> AST.t())) :: stage()
  def wrap_safe(fun) when is_function(fun, 1) do
    fn ast ->
      try do
        {:ok, fun.(ast)}
      rescue
        e ->
          {:error, "Error in pipeline stage: #{inspect(e)}"}
      end
    end
  end
end
