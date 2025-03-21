defmodule Portfolio.Content.MarkdownRendering.PipelineTest do
  use ExUnit.Case, async: false

  alias Portfolio.Content.MarkdownRendering.Pipeline
  alias Portfolio.Content.MarkdownRendering.AST
  alias Portfolio.Content.MarkdownRendering.Pipeline.Stage
  alias Portfolio.Content.MarkdownRendering.Pipeline.Stages

  describe "pipeline creation and execution" do
    test "creates a pipeline with stages" do
      pipeline = Pipeline.new([&Pipeline.identity/1])
      assert is_function(pipeline, 1)
    end

    test "processes AST through a pipeline" do
      # Create a simple pipeline
      pipeline = Pipeline.new([&Pipeline.identity/1])

      # Sample AST
      ast = [AST.text("Hello")]

      # Process the AST
      assert {:ok, ["Hello"]} = Pipeline.process(pipeline, ast)
    end

    test "pipeline halts on error" do
      # Create a pipeline with an error stage
      error_stage = fn _ast -> {:error, "Test error"} end
      pipeline = Pipeline.new([&Pipeline.identity/1, error_stage])

      # Process the AST
      assert {:error, "Test error"} =
               Pipeline.process(pipeline, [AST.text("Hello")])
    end

    test "adds stages to an existing pipeline" do
      # Create a basic pipeline
      pipeline = Pipeline.new([&Pipeline.identity/1])

      # Add a mapping stage
      uppercase_stage =
        Pipeline.map_stage(fn
          text when is_binary(text) -> String.upcase(text)
          node -> node
        end)

      extended_pipeline = Pipeline.add_stage(pipeline, uppercase_stage)

      # Test the pipeline
      assert {:ok, ["HELLO"]} =
               Pipeline.process(extended_pipeline, [AST.text("Hello")])
    end
  end

  describe "pipeline stage behavior" do
    # Create a test stage that implements the Stage behavior
    defmodule TestStage do
      use Pipeline.Stage, name: "Test Stage"

      @impl true
      def transform(ast, opts) do
        prefix = Keyword.get(opts, :prefix, "")

        result =
          AST.map(ast, fn
            text when is_binary(text) -> prefix <> text
            node -> node
          end)

        {:ok, result}
      end
    end

    test "creates a stage function from a module" do
      stage_fn = Stage.from_module(TestStage, prefix: "PREFIX: ")
      assert is_function(stage_fn, 1)

      result = stage_fn.([AST.text("Hello")])
      assert {:ok, ["PREFIX: Hello"]} = result
    end

    test "combines multiple stages in a pipeline" do
      stage1 = Stage.from_module(TestStage, prefix: "Stage1: ")
      stage2 = Stage.from_module(TestStage, prefix: "Stage2: ")

      pipeline = Pipeline.new([stage1, stage2])

      # Process through both stages
      result = Pipeline.process(pipeline, [AST.text("Hello")])
      assert {:ok, ["Stage2: Stage1: Hello"]} = result
    end
  end

  describe "using real pipeline stages" do
    setup do
      # Register a test component to use in the component resolution stage
      alias Portfolio.Content.MarkdownRendering.Components.Registry
      Registry.stop()
      {:ok, _} = start_supervised(Registry)

      :ok
    end

    test "processes AST through typography enhancement stage" do
      # Create an AST with element nodes that should be converted to typography components
      ast = [
        {"h1", %{}, ["Heading"], %{}},
        {"p", %{}, ["Paragraph"], %{}}
      ]

      # Create a typography enhancement stage
      stage = Stage.from_module(Stages.TypographyEnhancement)

      # Process the AST
      {:ok, transformed_ast} = stage.(ast)

      # Verify the transformation
      assert [first, second] = transformed_ast

      assert match?(
               {:component, :typography, %{tag: "h1"}, ["Heading"], _},
               first
             )

      assert match?(
               {:component, :typography, %{tag: "p"}, ["Paragraph"], _},
               second
             )
    end

    test "processes AST through layout processing stage" do
      # Create an AST with content
      ast = [
        {"h1", %{}, ["Title"], %{}},
        {"p", %{}, ["Content"], %{}}
      ]

      # Create metadata with layout instructions
      metadata = %{
        "layout" => "columns",
        "columns" => [
          %{"width" => "1", "content" => "main"},
          %{"width" => "2", "content" => "sidebar"}
        ]
      }

      # Create a layout processing stage
      stage = Stage.from_module(Stages.LayoutProcessing, metadata: metadata)

      # Process the AST
      {:ok, transformed_ast} = stage.(ast)

      # Verify the transformation
      assert [column_layout] = transformed_ast

      assert match?(
               {:component, :column_layout, %{columns: _}, _, _},
               column_layout
             )
    end
  end
end
