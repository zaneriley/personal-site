defmodule Portfolio.Content.MarkdownRendering.RendererTest do
  use Portfolio.DataCase
  alias Portfolio.Content.MarkdownRendering.Renderer
  alias Portfolio.Cache

  setup do
    # Align with CacheTest setup
    :ok = Application.put_env(:portfolio, :cache, disabled: false)
    on_exit(fn -> Application.delete_env(:portfolio, :cache) end)
    Cache.clear()
    :verify_on_exit!
    :ok
  end

  describe "render_and_cache/4" do
    test "renders simple markdown to HTML" do
      markdown = "# Hello"
      {:ok, html} = Renderer.render_and_cache(markdown, :note, "test_1")
      {:ok, parsed} = Floki.parse_fragment(html)
      assert [{"h1", _, ["Hello"]}] = Floki.find(parsed, "h1")
    end

    test "renders complex markdown with various elements" do
      markdown = """
      # Header

      **Bold** and *italic*

      - List item 1
      - List item 2

      ```elixir
      def hello, do: "world"
      ```

      [Link](https://example.com)

      ![Image](https://example.com/image.jpg)
      """

      {:ok, html} = Renderer.render_and_cache(markdown, :post, "test_2")
      {:ok, parsed} = Floki.parse_fragment(html)

      # Check header
      assert [{"h1", _, ["Header"]}] = Floki.find(parsed, "h1")

      # Check paragraphs
      paragraphs = Floki.find(parsed, "p")
      assert length(paragraphs) == 3

      # Check paragraph with bold and italic
      [first_p | _] = paragraphs
      assert Floki.text(first_p) =~ "Bold and italic"
      assert [{"strong", _, ["Bold"]}] = Floki.find(first_p, "strong")
      assert [{"em", _, ["italic"]}] = Floki.find(first_p, "em")

      # Check list
      assert [ul] = Floki.find(parsed, "ul")

      assert [{"li", _, ["List item 1"]}, {"li", _, ["List item 2"]}] =
               Floki.find(ul, "li")

      # Check code block
      assert [{"code", [{"class", "elixir"}], [code_content]}] =
               Floki.find(parsed, "code.elixir")

      assert code_content == "def hello, do: \"world\""

      # Check link
      assert [{"a", [{"href", "https://example.com"}], ["Link"]}] =
               Floki.find(parsed, "p a[href='https://example.com']")

    end

    test "caches content after first render" do
      markdown = "## Cached Content"
      cache_key = "compiled_content:test_3"

      refute Portfolio.Cache.exists?(cache_key)
      {:ok, html1} = Renderer.render_and_cache(markdown, :note, "test_3")
      assert Portfolio.Cache.exists?(cache_key)
      {:ok, html2} = Renderer.render_and_cache(markdown, :note, "test_3")
      assert html1 == html2
    end

    test "force refresh option bypasses cache" do
      markdown = "### Force Refresh"
      cache_key = "compiled_content:test_4"

      {:ok, html1} = Renderer.render_and_cache(markdown, :note, "test_4")
      assert Portfolio.Cache.exists?(cache_key)

      # Modify the cached content directly to simulate a change
      {:ok, true} = Portfolio.Cache.put(cache_key, "Old content")

      {:ok, html2} =
        Renderer.render_and_cache(markdown, :note, "test_4",
          force_refresh: true
        )

      assert html1 == html2
      assert html2 != "Old content"
    end

    test "bypass cache option" do
      markdown = "#### Bypass Cache"
      cache_key = "compiled_content:test_5"

      {:ok, html1} =
        Renderer.render_and_cache(markdown, :note, "test_5", bypass_cache: true)

      refute Portfolio.Cache.exists?(cache_key)

      {:ok, html2} =
        Renderer.render_and_cache(markdown, :note, "test_5", bypass_cache: true)

      refute Portfolio.Cache.exists?(cache_key)
      assert html1 == html2
    end

    test "handles empty content" do
      {:error, :empty_content} = Renderer.render_and_cache("", :note, "test_6")
    end

    test "handles non-markdown content" do
      content = "<p>HTML content</p>"

      {:ok, html} =
        Renderer.render_and_cache(content, :note, "test_7", is_markdown: false)

      assert html == content
    end
  end

  describe "invalidate_cache/1" do
    test "removes content from cache" do
      markdown = "##### Invalidate Test"
      cache_key = "compiled_content:test_8"

      {:ok, _} = Renderer.render_and_cache(markdown, :note, "test_8")
      assert Portfolio.Cache.exists?(cache_key)

      :ok = Renderer.invalidate_cache("test_8")
      refute Portfolio.Cache.exists?(cache_key)
    end
  end
end
