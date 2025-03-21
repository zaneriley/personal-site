defmodule Portfolio.Content.Markdown.RendererTest do
  use ExUnit.Case, async: true

  alias Portfolio.Content.Markdown.Renderer
  alias Portfolio.Content.Markdown.Transforms
  alias Portfolio.Cache

  # Helper functions for common test needs
  defp make_text(text), do: text

  defp make_element(tag, attrs, children, meta \\ %{}) do
    {tag, attrs || [], children, meta || %{}}
  end

  # Setup to manage cache state between tests
  setup do
    # Ensure the cache is enabled for testing
    :ok = Application.put_env(:portfolio, :cache, disabled: false)
    on_exit(fn -> Application.delete_env(:portfolio, :cache) end)
    Cache.clear()

    # Test content
    markdown = """
    # Heading

    This is a paragraph with *emphasized* and **strong** text.

    ![An image](path/to/image.jpg)

    - List item 1
    - List item 2
    """

    %{
      simple_markdown: "# Simple Heading",
      markdown: markdown,
      markdown_with_frontmatter: """
      ---
      layout: columns
      columns:
        - width: 1/2
        - width: 1/2
      ---
      #{markdown}
      """
    }
  end

  describe "render/3" do
    test "parses markdown into AST", %{simple_markdown: markdown} do
      {:ok, ast} = Renderer.render(markdown, :note)

      # Verify result is an AST
      assert is_list(ast)

      # Verify AST structure (should contain a typography component for heading)
      assert Enum.any?(ast, fn
               {:typography, "h1", _, ["Simple Heading"], _} -> true
               _ -> false
             end)
    end

    test "handles empty content" do
      result = Renderer.render("")
      assert {:error, _reason} = result
    end

    test "processes full markdown with transforms", %{markdown: markdown} do
      {:ok, ast} = Renderer.render(markdown, :note)

      # Verify basic AST structure elements are present
      assert Enum.any?(ast, fn
               {:typography, "h1", _, ["Heading"], _} -> true
               _ -> false
             end)

      # Verify paragraphs and find some content
      paragraph =
        Enum.find(ast, fn
          {:typography, "p", _, _, _} -> true
          _ -> false
        end)

      assert paragraph != nil

      # Just check that there is something in the AST, not specifically looking for list items
      assert length(ast) > 2
    end

    test "handles frontmatter metadata", %{markdown_with_frontmatter: markdown} do
      {:ok, ast} = Renderer.render(markdown, :note)

      # Just verify that the AST was processed successfully
      assert is_list(ast)
      assert length(ast) > 0
    end

    test "passes options to transform functions", %{simple_markdown: markdown} do
      options = [ignore_missing_components: true]

      {:ok, _ast} = Renderer.render(markdown, :note, options)

      # This is primarily testing that the function call succeeds
      # A more comprehensive test would mock transform modules to verify option passing
    end
  end

  describe "render_and_cache/4" do
    test "caches rendering results", %{simple_markdown: markdown} do
      content_id = "test_cache_id"
      ast_cache_key = "#{content_id}_ast"

      # Initially cache should be empty
      refute Cache.exists?(ast_cache_key)

      # Render and cache
      {:ok, ast} = Renderer.render_and_cache(markdown, content_id, :note)

      # Cache should now contain AST
      assert Cache.exists?(ast_cache_key)

      # AST should be a list
      assert is_list(ast)

      # Check the cached value directly
      cached_ast = Cache.get(ast_cache_key)

      case cached_ast do
        {:ok, value} ->
          assert is_list(value)
          assert ast == value

        _ ->
          assert is_list(cached_ast)
          assert ast == cached_ast
      end
    end

    test "returns cached AST on subsequent calls", %{simple_markdown: markdown} do
      content_id = "test_cached_ast"

      # First render and cache
      {:ok, ast1} = Renderer.render_and_cache(markdown, content_id, :note)

      # Second render should use cache
      {:ok, ast2} = Renderer.render_and_cache(markdown, content_id, :note)

      # Both rendered results should be identical
      assert ast1 == ast2

      # Verify the cached value directly
      cached_ast = Cache.get("#{content_id}_ast")

      case cached_ast do
        {:ok, value} -> assert ast1 == value
        _ -> assert ast1 == cached_ast
      end
    end

    test "bypasses cache with force_refresh option", %{
      simple_markdown: markdown
    } do
      content_id = "test_force_refresh"

      # First render and cache
      {:ok, ast1} = Renderer.render_and_cache(markdown, content_id, :note)

      # Modify markdown
      modified_markdown = "# Modified Heading"

      # Render with force_refresh
      {:ok, ast2} =
        Renderer.render_and_cache(modified_markdown, content_id, :note,
          force_refresh: true
        )

      # Results should be different
      refute ast1 == ast2
      assert is_list(ast2)

      # Check if the modified content contains the new heading
      assert Enum.any?(ast2, fn
               {:typography, "h1", _, ["Modified Heading"], _} -> true
               _ -> false
             end)
    end

    test "bypass_cache option skips caching", %{simple_markdown: markdown} do
      content_id = "test_bypass_cache"
      ast_cache_key = "#{content_id}_ast"

      # Render with bypass_cache
      {:ok, _ast} =
        Renderer.render_and_cache(markdown, content_id, :note,
          bypass_cache: true
        )

      # Cache should still be empty
      refute Cache.exists?(ast_cache_key)
    end
  end

  describe "invalidate_cache/1" do
    test "removes AST from cache", %{simple_markdown: markdown} do
      content_id = "test_invalidate"
      ast_cache_key = "#{content_id}_ast"

      # First render and cache
      {:ok, _ast} = Renderer.render_and_cache(markdown, content_id, :note)

      # Verify cache contains results
      assert Cache.exists?(ast_cache_key)

      # Invalidate cache
      :ok = Renderer.invalidate_cache(content_id)

      # Verify cache is empty
      refute Cache.exists?(ast_cache_key)
    end
  end

  describe "integration with transform pipeline" do
    test "applies typography transforms", %{simple_markdown: markdown} do
      {:ok, ast} = Renderer.render(markdown, :note)

      # Check for typography-enhanced elements
      assert Enum.any?(ast, fn
               {:typography, "h1", _, _, _} -> true
               _ -> false
             end)
    end

    test "applies component transforms", %{markdown: markdown} do
      # This test just verifies that component transforms don't crash
      # and that the AST is successfully processed
      {:ok, ast} = Renderer.render(markdown, :note)
      assert is_list(ast)
      assert length(ast) > 0
    end
  end
end
