defmodule Portfolio.Content.MarkdownRendering.RendererIntegrationTest do
  use Portfolio.DataCase

  alias Portfolio.Content.MarkdownRendering.Renderer
  alias Portfolio.Content.MarkdownRendering.Pipeline
  alias Portfolio.Content.MarkdownRendering.Pipeline.Stage

  alias Portfolio.Content.MarkdownRendering.Pipeline.Stages.TypographyEnhancement

  alias Portfolio.Cache

  setup do
    # Clear cache before each test
    Cache.clear()

    # Test content
    markdown = """
    # Test Heading

    This is a paragraph with *emphasized* and **strong** text.

    ![An image](path/to/image.jpg)

    - List item 1
    - List item 2
    """

    %{markdown: markdown}
  end

  describe "render/2" do
    test "returns an AST for the provided markdown", %{markdown: markdown} do
      {:ok, ast} = Renderer.render(markdown)

      # Verify the result is a properly structured AST
      assert is_list(ast)
      assert length(ast) > 0

      # Check for expected elements in the AST
      heading =
        Enum.find(ast, fn node ->
          case node do
            {"h1", _, _, _} -> true
            _ -> false
          end
        end)

      assert heading != nil
    end

    test "processes the AST through a pipeline based on content type", %{
      markdown: markdown
    } do
      {:ok, ast} = Renderer.render(markdown, content_type: :note)

      # Verify that typography enhancements were applied
      paragraph =
        Enum.find(ast, fn node ->
          case node do
            {"p", _, _, _} -> true
            _ -> false
          end
        end)

      assert paragraph != nil

      # Find emphasized text in the paragraph
      emphasized_text = find_emphasized_text(paragraph)
      assert emphasized_text != nil
    end

    test "handles frontmatter metadata", %{markdown: markdown} do
      # Add frontmatter to the markdown
      markdown_with_frontmatter = """
      ---
      layout: column
      columns:
        - width: 1/2
        - width: 1/2
      ---
      #{markdown}
      """

      {:ok, ast} = Renderer.render(markdown_with_frontmatter)

      # Check if layout processing was applied based on frontmatter
      column_layout =
        Enum.find(ast, fn node ->
          case node do
            {:component, :column_layout, _, _, _} -> true
            _ -> false
          end
        end)

      assert column_layout != nil
    end
  end

  describe "render_and_cache/4" do
    test "renders and caches both HTML and AST", %{markdown: markdown} do
      content_id = "test_content_id"

      # First call should render and cache
      {:ok, html} = Renderer.render_and_cache(markdown, :note, content_id)

      # Verify HTML was rendered correctly
      assert is_binary(html)
      assert html =~ "<h1>"
      assert html =~ "<p>"

      # Verify HTML was cached
      assert Cache.exists?("compiled_content:#{content_id}")

      # Verify AST was cached
      assert Cache.exists?("ast:#{content_id}")

      # Get AST from cache
      {:ok, cached_ast} =
        Renderer.render_and_cache(markdown, :note, content_id, return_ast: true)

      assert is_list(cached_ast)
    end

    test "returns cached HTML when available", %{markdown: markdown} do
      content_id = "cached_content_id"

      # First call should render and cache
      {:ok, html1} = Renderer.render_and_cache(markdown, :note, content_id)

      # Second call should use cache
      {:ok, html2} = Renderer.render_and_cache(markdown, :note, content_id)

      # Both calls should return the same HTML
      assert html1 == html2
    end

    test "returns cached AST when available and requested", %{
      markdown: markdown
    } do
      content_id = "cached_ast_id"

      # First call should render and cache the AST
      {:ok, ast1} =
        Renderer.render_and_cache(markdown, :note, content_id, return_ast: true)

      # Second call should use cached AST
      {:ok, ast2} =
        Renderer.render_and_cache(markdown, :note, content_id, return_ast: true)

      # Both calls should return the same AST
      assert ast1 == ast2
    end

    test "forces refresh when requested", %{markdown: markdown} do
      content_id = "force_refresh_id"

      # First call should render and cache
      {:ok, _} = Renderer.render_and_cache(markdown, :note, content_id)

      # Modify the markdown
      modified_markdown = markdown <> "\n\nAdditional content."

      # Call with force_refresh should re-render
      {:ok, html} =
        Renderer.render_and_cache(modified_markdown, :note, content_id,
          force_refresh: true
        )

      # Verify HTML contains the additional content
      assert html =~ "Additional content"
    end
  end

  describe "invalidate_cache/1" do
    test "invalidates both HTML and AST cache", %{markdown: markdown} do
      content_id = "invalidate_cache_id"

      # Render and cache
      {:ok, _} = Renderer.render_and_cache(markdown, :note, content_id)

      # Verify both HTML and AST are cached
      assert Cache.exists?("compiled_content:#{content_id}")
      assert Cache.exists?("ast:#{content_id}")

      # Invalidate cache
      :ok = Renderer.invalidate_cache(content_id)

      # Verify both HTML and AST are no longer cached
      refute Cache.exists?("compiled_content:#{content_id}")
      refute Cache.exists?("ast:#{content_id}")
    end
  end

  # Helper function to find emphasized text in a node
  defp find_emphasized_text({"p", _, content, _}) do
    Enum.find(content, fn node ->
      case node do
        {"em", _, _, _} -> true
        _ -> false
      end
    end)
  end

  defp find_emphasized_text(_), do: nil
end
