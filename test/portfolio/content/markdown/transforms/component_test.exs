defmodule Portfolio.Content.Markdown.Transforms.ComponentTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  # Module doesn't exist yet, but we're defining tests first per TDD
  alias Portfolio.Content.Markdown.Transforms.Component

  describe "apply/2" do
    test "resolves component nodes with valid types" do
      ast = [
        {:component, "button", %{size: "small"}, ["Click me"], %{}}
      ]

      # Mock component registry lookup
      registry_fn = fn "button" ->
        {:ok, %{module: PortfolioWeb.Components.Button}}
      end

      {:ok, transformed} = Component.apply(ast, registry_fn: registry_fn)

      assert [
               {:component, "button", %{size: "small"}, ["Click me"],
                %{module: PortfolioWeb.Components.Button}}
             ] = transformed
    end

    test "preserves HTML element nodes and transforms their content" do
      ast = [
        {:element, "div", %{class: "container"},
         [
           {:component, "button", %{size: "small"}, ["Click me"], %{}}
         ], %{}}
      ]

      # Mock component registry lookup
      registry_fn = fn "button" ->
        {:ok, %{module: PortfolioWeb.Components.Button}}
      end

      {:ok, transformed} = Component.apply(ast, registry_fn: registry_fn)

      assert [
               {:element, "div", %{class: "container"},
                [
                  {:component, "button", %{size: "small"}, ["Click me"],
                   %{module: PortfolioWeb.Components.Button}}
                ], %{}}
             ] = transformed
    end

    test "returns error for missing components when ignore_missing is false" do
      ast = [
        {:component, "non_existent", %{}, ["Content"], %{}}
      ]

      # Mock component registry lookup that returns nil for non-existent components
      registry_fn = fn "non_existent" -> nil end

      result =
        Component.apply(ast, registry_fn: registry_fn, ignore_missing: false)

      assert {:error, "Component 'non_existent' not found in registry"} = result
    end

    test "keeps missing components when ignore_missing is true" do
      ast = [
        {:component, "non_existent", %{}, ["Content"], %{}}
      ]

      # Mock component registry lookup that returns nil for non-existent components
      registry_fn = fn "non_existent" -> nil end

      log_output =
        capture_log(fn ->
          {:ok, transformed} =
            Component.apply(ast, registry_fn: registry_fn, ignore_missing: true)

          assert [
                   {:component, "non_existent", %{}, ["Content"], %{}}
                 ] = transformed
        end)

      assert log_output =~
               "Component 'non_existent' not found, but ignore_missing is true"
    end

    test "processes typography nodes without registry lookup" do
      ast = [
        {:typography, "p", %{size: "base"}, ["Paragraph text"], %{}}
      ]

      # Should not be called for typography
      registry_fn = fn _ -> nil end

      {:ok, transformed} = Component.apply(ast, registry_fn: registry_fn)

      assert [
               {:typography, "p", %{size: "base"}, ["Paragraph text"], %{}}
             ] = transformed
    end

    test "processes nested content in components recursively" do
      ast = [
        {:component, "card", %{},
         [
           {:component, "button", %{}, ["Nested"], %{}}
         ], %{}}
      ]

      # Mock registry that knows both components
      registry_fn = fn
        "card" -> {:ok, %{module: PortfolioWeb.Components.Card}}
        "button" -> {:ok, %{module: PortfolioWeb.Components.Button}}
      end

      {:ok, transformed} = Component.apply(ast, registry_fn: registry_fn)

      assert [
               {:component, "card", %{},
                [
                  {:component, "button", %{}, ["Nested"],
                   %{module: PortfolioWeb.Components.Button}}
                ], %{module: PortfolioWeb.Components.Card}}
             ] = transformed
    end
  end
end
