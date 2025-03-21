defmodule Portfolio.Content.Markdown.PipelineTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  # Module doesn't exist yet, but we're defining tests first per TDD
  alias Portfolio.Content.Markdown.Pipeline

  # Create a helper to make valid AST nodes
  defp make_text(text), do: text

  defp make_element(tag, attrs, children, meta \\ %{}) do
    {tag, attrs || [], children, meta || %{}}
  end

  # Define test modules for stages without using mocks
  defmodule TestStage1 do
    def apply(ast, _opts \\ []) do
      transformed =
        Enum.map(ast, fn
          {tag, attrs, children, meta} when is_binary(tag) ->
            processed_attrs = Map.put(Map.new(attrs), :processed_by, [:test1])
            {:typography, tag, processed_attrs, children, meta}

          node ->
            node
        end)

      {:ok, transformed}
    end
  end

  defmodule TestStage2 do
    def apply(ast, _opts \\ []) do
      transformed =
        Enum.map(ast, fn
          {:typography, tag, attrs, children, meta} ->
            updated_attrs =
              Map.update(attrs, :processed_by, [:test2], fn existing ->
                [:test2 | existing]
              end)

            {:typography, tag, updated_attrs, children, meta}

          node ->
            node
        end)

      {:ok, transformed}
    end
  end

  defmodule ErrorStage do
    def apply(_ast, _opts \\ []) do
      {:error, "Error in pipeline stage"}
    end
  end

  defmodule OptionCheckStage do
    def apply(ast, opts \\ []) do
      transformed =
        Enum.map(ast, fn
          {tag, _attrs, children, meta} when is_binary(tag) ->
            {:typography, tag, %{received_options: opts}, children, meta}

          node ->
            node
        end)

      {:ok, transformed}
    end
  end

  describe "process/2" do
    test "processes AST through configured stages" do
      # Simple AST with basic elements
      ast = [
        make_element("h1", [], [make_text("Test Heading")]),
        make_element("p", [], [make_text("Test paragraph")])
      ]

      # Configure stages
      stages = [
        TestStage1,
        TestStage2
      ]

      {:ok, result} = Pipeline.process(ast, stages: stages)

      # Verify stages transformed the content appropriately
      assert [
               {:typography, "h1", h1_attrs, ["Test Heading"], _},
               {:typography, "p", p_attrs, ["Test paragraph"], _}
             ] = result

      # Check that both stages processed the content in the right order
      assert h1_attrs.processed_by == [:test2, :test1]
      assert p_attrs.processed_by == [:test2, :test1]
    end

    test "halts pipeline on stage error" do
      ast = [make_element("h1", [], [make_text("Test Heading")])]

      stages = [
        # This stage will return an error
        ErrorStage
      ]

      result = Pipeline.process(ast, stages: stages)

      assert {:error, "Error in pipeline stage"} = result
    end

    test "forwards options to each stage" do
      ast = [make_element("p", [], [make_text("Test")])]

      options = [
        test_option: "test_value",
        metadata: %{"layout" => "columns"}
      ]

      {:ok, result} =
        Pipeline.process(
          ast,
          Keyword.merge([stages: [OptionCheckStage]], options)
        )

      # The OptionCheckStage should add the received option to the result
      assert [
               {:typography, "p", %{received_options: received_opts}, ["Test"],
                %{}}
             ] = result

      assert received_opts[:test_option] == "test_value"
      assert received_opts[:metadata]["layout"] == "columns"
    end
  end
end
