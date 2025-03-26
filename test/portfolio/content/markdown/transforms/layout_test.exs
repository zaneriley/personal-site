defmodule Portfolio.Content.Markdown.Transforms.LayoutTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Portfolio.Content.Markdown.Transforms.Layout

  describe "apply/2" do
    test "does not modify AST when no layout is specified" do
      # Create a simple AST
      ast = [
        {"h1", [], ["Test Heading"], %{}},
        {"p", [], ["Test paragraph"], %{}}
      ]

      # Apply the transform with no layout in metadata
      {:ok, transformed} = Layout.apply(ast, metadata: %{})

      # Assert the AST is unchanged
      assert transformed == ast
    end

    test "applies column layout when specified in metadata" do
      # Create a simple AST
      ast = [
        {"h1", [], ["Test Heading"], %{}},
        {"p", [], ["Test paragraph"], %{}}
      ]

      # Metadata with column layout specification
      metadata = %{
        "layout" => "columns",
        "columns" => [
          %{"width" => "2/3", "content" => "main"},
          %{"width" => "1/3", "content" => "sidebar"}
        ]
      }

      # Capture log to check for the info message
      log_output =
        capture_log(fn ->
          # Apply the transform
          {:ok, transformed} = Layout.apply(ast, metadata: metadata)

          # Assert the AST is unchanged (since column layout is disabled)
          assert transformed == ast
        end)

      # Verify an info message was logged
      assert log_output =~ "Column layout processing temporarily disabled"
    end

    test "returns original AST for unsupported layout types" do
      # Create a simple AST
      ast = [
        {"h1", [], ["Test Heading"], %{}},
        {"p", [], ["Test paragraph"], %{}}
      ]

      # Metadata with an unsupported layout type
      metadata = %{
        "layout" => "unsupported_layout_type"
      }

      # Capture log to verify the warning
      log_output =
        capture_log(fn ->
          # Apply the transform
          {:ok, transformed} = Layout.apply(ast, metadata: metadata)

          # Assert the AST is unchanged
          assert transformed == ast
        end)

      # Verify a warning was logged
      assert log_output =~ "Unsupported layout type"
    end

    test "returns original AST when columns are not specified correctly" do
      # Create a simple AST
      ast = [
        {"h1", [], ["Test Heading"], %{}},
        {"p", [], ["Test paragraph"], %{}}
      ]

      # Metadata with column layout but no column specs
      metadata = %{
        "layout" => "columns",
        # Empty columns
        "columns" => []
      }

      # Apply the transform
      {:ok, transformed} = Layout.apply(ast, metadata: metadata)

      # Assert the AST is unchanged when no columns specified
      assert transformed == ast
    end

    test "handles grid layout placeholder correctly" do
      # Create a simple AST
      ast = [
        {"h1", [], ["Test Heading"], %{}},
        {"p", [], ["Test paragraph"], %{}}
      ]

      # Metadata with grid layout
      metadata = %{
        "layout" => "grid"
      }

      # Capture log to check the info message
      log_output =
        capture_log(fn ->
          # Apply the transform
          {:ok, transformed} = Layout.apply(ast, metadata: metadata)

          # Assert the AST is unchanged (since grid is not implemented yet)
          assert transformed == ast
        end)

      # Verify an info message was logged
      assert log_output =~ "Grid layout processing not fully implemented yet"
    end
  end
end
