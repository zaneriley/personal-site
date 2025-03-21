defmodule Portfolio.Content.MarkdownRendering.Pipeline.Stage do
  @moduledoc """
  Defines the behavior for pipeline stages in the markdown rendering system.

  Each pipeline stage is responsible for a specific transformation of the AST,
  such as resolving components, enhancing typography, or processing layouts.

  Stages receive an AST, perform their transformation, and return the transformed AST
  or an error if the transformation failed.
  """

  alias Portfolio.Content.MarkdownRendering.AST

  @doc """
  Process an AST through this pipeline stage.

  Each implementation should take an AST, apply its specific transformation,
  and return either `{:ok, transformed_ast}` or `{:error, reason}`.

  ## Parameters

  - `ast` - The AST to transform
  - `opts` - Optional parameters for the transformation

  ## Returns

  - `{:ok, transformed_ast}` if the transformation was successful
  - `{:error, reason}` if the transformation failed
  """
  @callback process(ast :: AST.t(), opts :: keyword()) ::
              {:ok, AST.t()} | {:error, String.t()}

  @doc """
  Returns a human-readable name for this stage.

  Used for logging and debugging pipeline execution.
  """
  @callback name() :: String.t()

  @doc """
  Creates a pipeline stage function from a module implementing this behavior.

  ## Examples

      defmodule MyStage do
        @behaviour Portfolio.Content.MarkdownRendering.Pipeline.Stage

        @impl true
        def process(ast, _opts) do
          {:ok, ast}
        end

        @impl true
        def name, do: "My Stage"
      end

      # Create a stage function
      stage_fn = Stage.from_module(MyStage)

      # Use it in a pipeline
      pipeline = Pipeline.new([stage_fn])
  """
  @spec from_module(module(), keyword()) ::
          (AST.t() -> {:ok, AST.t()} | {:error, String.t()})
  def from_module(module, opts \\ []) do
    fn ast ->
      require Logger
      Logger.debug("Starting pipeline stage: #{module.name()}")

      start_time = System.monotonic_time()
      result = module.process(ast, opts)
      end_time = System.monotonic_time()

      duration_ms =
        System.convert_time_unit(end_time - start_time, :native, :millisecond)

      case result do
        {:ok, transformed_ast} ->
          Logger.debug(
            "Completed pipeline stage: #{module.name()} in #{duration_ms}ms"
          )

          {:ok, transformed_ast}

        {:error, reason} ->
          Logger.error("Failed pipeline stage: #{module.name()} - #{reason}")
          {:error, reason}
      end
    end
  end

  @doc """
  A macro to simplify creation of pipeline stages.

  This macro implements the Stage behavior and provides common functionality,
  allowing you to focus on the transformation logic.

  ## Examples

      defmodule Portfolio.Content.MarkdownRendering.Pipeline.Stages.MyStage do
        use Portfolio.Content.MarkdownRendering.Pipeline.Stage, name: "My Custom Stage"

        @impl true
        def transform(ast, _opts) do
          # Your transformation logic here
          {:ok, ast}
        end
      end
  """
  defmacro __using__(opts) do
    quote location: :keep do
      @behaviour Portfolio.Content.MarkdownRendering.Pipeline.Stage

      @stage_name unquote(opts[:name]) ||
                    __MODULE__ |> Module.split() |> List.last()

      # Default implementation that delegates to transform/2
      @impl true
      def process(ast, opts) do
        transform(ast, opts)
      end

      @impl true
      def name, do: @stage_name

      # To be overridden by the using module
      def transform(ast, _opts) do
        {:ok, ast}
      end

      # Allow overriding the default implementations
      defoverridable process: 2, name: 0, transform: 2
    end
  end
end
