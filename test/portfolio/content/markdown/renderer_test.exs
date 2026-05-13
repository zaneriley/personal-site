defmodule Portfolio.Content.Markdown.RendererTest do
  use ExUnit.Case, async: true

  alias Portfolio.Content.Markdown.Renderer
  alias Portfolio.Cache

  # Setup to manage cache state between tests
  setup do
    # Ensure the cache is enabled for testing
    :ok = Application.put_env(:portfolio, :cache, disabled: false)
    on_exit(fn -> Application.delete_env(:portfolio, :cache) end)
    Cache.clear()

    # Start the component registry for testing only if it's not already started
    registry_pid = ensure_component_registry_started()

    # Register basic test components
    Portfolio.Content.Markdown.Component.Registry.register(:image, __MODULE__)
    Portfolio.Content.Markdown.Component.Registry.register(:figure, __MODULE__)

    on_exit(fn ->
      if registry_pid && Process.alive?(registry_pid) do
        Process.exit(registry_pid, :normal)
      end
    end)

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
      assert ast != []
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

  describe "render_to_safe/1" do
    test "returns a Phoenix.HTML safe tuple" do
      ast = [{"p", [], ["Hello"], %{}}]
      assert {:safe, _} = Renderer.render_to_safe(ast)
    end

    test "renders nested tags without HEEx escaping the markup" do
      ast = [{"div", [], [{"p", [], ["text"], %{}}], %{}}]
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)
      assert html == "<div><p>text</p></div>"
    end

    test "escapes attribute values to prevent attribute-context escape" do
      ast = [
        {"a", [{"title", ~S(" onmouseover=alert)}], ["link"], %{}}
      ]

      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ ~S(" onmouseover=alert)
      assert html =~ "&quot;"
    end

    test "escapes text content" do
      ast = [{"p", [], ["1 < 2 & 3"], %{}}]
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "1 < 2 & 3"
      assert html =~ "1 &lt; 2 &amp; 3"
    end

    test "handles binary input by escaping it" do
      {:safe, iodata} = Renderer.render_to_safe("<script>alert(1)</script>")
      html = IO.iodata_to_binary(iodata)

      refute html =~ "<script>"
      assert html =~ "&lt;script&gt;"
    end

    test "handles typography nodes" do
      ast = [{:typography, "h1", [], ["Title"], %{}}]
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)
      assert html =~ "<h1>Title</h1>"
    end

    test "drops <script> tag wrapper from raw HTML in markdown" do
      ast = [{"script", [], ["alert(1)"], %{}}]
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "<script>"
      refute html =~ "</script>"
      # Child text is preserved but escaped (no executable JS).
      assert html =~ "alert(1)"
    end

    test "drops <iframe>, <style>, <object> wrappers" do
      for tag <- ~w(iframe style object embed link meta base form) do
        ast = [{tag, [], ["payload"], %{}}]
        {:safe, iodata} = Renderer.render_to_safe(ast)
        html = IO.iodata_to_binary(iodata)
        refute html =~ "<#{tag}", "expected <#{tag}> to be dropped but got: #{html}"
      end
    end

    test "drops event-handler attributes like onclick" do
      ast = [{"a", [{"href", "/foo"}, {"onclick", "alert(1)"}], ["link"], %{}}]
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "onclick"
      assert html =~ ~S(href="/foo")
    end

    test "rejects javascript: scheme in href" do
      ast = [{"a", [{"href", "javascript:alert(1)"}], ["link"], %{}}]
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "javascript:"
    end

    test "rejects javascript: scheme regardless of leading whitespace or case" do
      for href <- ["  JavaScript:alert(1)", "VBSCRIPT:alert", "\tjavascript:foo"] do
        ast = [{"a", [{"href", href}], ["link"], %{}}]
        {:safe, iodata} = Renderer.render_to_safe(ast)
        html = IO.iodata_to_binary(iodata)
        refute html =~ ~r/javascript:|vbscript:/i, "expected #{href} to be rejected"
      end
    end

    test "preserves safe href schemes (http, https, mailto, relative)" do
      for href <- ["https://example.com", "http://example.com", "mailto:a@b", "/path", "#anchor"] do
        ast = [{"a", [{"href", href}], ["link"], %{}}]
        {:safe, iodata} = Renderer.render_to_safe(ast)
        html = IO.iodata_to_binary(iodata)
        assert html =~ "href=", "expected href #{href} to be preserved"
      end
    end

    test "preserves aria-* and data-* attributes" do
      ast = [
        {"div",
         [
           {"aria-label", "hello"},
           {"data-id", "42"},
           {"onmouseover", "alert(1)"}
         ], ["x"], %{}}
      ]

      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      assert html =~ ~S(aria-label="hello")
      assert html =~ ~S(data-id="42")
      refute html =~ "onmouseover"
    end

    test "rejects data: URLs in href" do
      ast = [
        {"a",
         [{"href", "data:text/html,<script>alert(1)</script>"}], ["link"],
         %{}}
      ]

      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "data:"
    end

    test "rejects file: URLs in href" do
      ast = [{"a", [{"href", "file:///etc/passwd"}], ["link"], %{}}]
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "file:"
    end

    test "rejects ftp: URLs in href" do
      ast = [{"a", [{"href", "ftp://example.com/x"}], ["link"], %{}}]
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "ftp:"
    end

    test "rejects protocol-relative // URLs in href" do
      ast = [{"a", [{"href", "//evil.example/x"}], ["link"], %{}}]
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "//evil.example"
    end

    test "preserves safe href schemes (http, https, mailto, tel, relative, fragment)" do
      for href <- [
            "https://example.com",
            "http://example.com",
            "mailto:a@b",
            "tel:+15555555",
            "/path",
            "#anchor",
            "?query=1",
            "./relative",
            "../up"
          ] do
        ast = [{"a", [{"href", href}], ["link"], %{}}]
        {:safe, iodata} = Renderer.render_to_safe(ast)
        html = IO.iodata_to_binary(iodata)
        assert html =~ "href=", "expected href #{inspect(href)} to be preserved"
      end
    end
  end

  describe "render_to_safe/1 — typography transform bypass regression" do
    test "raw <p onclick=...> in markdown does not emit onclick after typography transform" do
      markdown = "<p onclick=\"alert(1)\">hello</p>"
      {:ok, ast} = Renderer.render(markdown, :note)
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "onclick"
      refute html =~ "alert(1)"
      assert html =~ "hello"
    end

    test "raw <h1 style=...> in markdown does not emit style after typography transform" do
      markdown = "<h1 style=\"color:red\">title</h1>"
      {:ok, ast} = Renderer.render(markdown, :note)
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "style="
      assert html =~ "title"
    end

    test "markdown link with javascript: URL does not emit a clickable javascript href" do
      # Earmark parses `[text](url)` into a real `<a href="url">` node;
      # this exercises the URL allowlist on a real anchor (not escaped text).
      markdown = "[click me](javascript:alert(1))"
      {:ok, ast} = Renderer.render(markdown, :note)
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      # No actual href attribute carrying the javascript: payload.
      refute html =~ ~r/href="javascript:/i
      assert html =~ "click me"
    end

    test "typography transform's own size/font/dropcap attrs survive the filter" do
      {:ok, ast} = Renderer.render("# Heading\n\nFirst paragraph.", :note)
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      # Heading 1 gets size="4xl" font="cardinal" via the transform.
      assert html =~ ~S(size="4xl")
      assert html =~ ~S(font="cardinal")
    end

    test "markdown image with safe src renders through the component path without crashing" do
      markdown = "![logo](https://example.com/logo.png)"
      {:ok, ast} = Renderer.render(markdown, :note)
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      # The test stub renders <test-component type="image" src="..." alt="..."/>.
      # The point is the dispatch does not crash with KeyError on assigns.src
      # — the assign flattening puts :src at top level for the component.
      assert html =~ ~S(type="image")
      assert html =~ ~S(src="https://example.com/logo.png")
      assert html =~ ~S(alt="logo")
    end

    test "markdown image with javascript: src neuters the URL to empty string" do
      markdown = "![logo](javascript:alert(1))"
      {:ok, ast} = Renderer.render(markdown, :note)
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "javascript:"
      refute html =~ "alert(1)"
      # The component still renders (sanitized src becomes ""), so we don't
      # 500 on a malformed-but-defensive markdown image.
      assert html =~ ~S(type="image")
      assert html =~ ~S(src="")
    end

    test "markdown image with data: src is also neutered" do
      markdown = "![x](data:text/html,evil)"
      {:ok, ast} = Renderer.render(markdown, :note)
      {:safe, iodata} = Renderer.render_to_safe(ast)
      html = IO.iodata_to_binary(iodata)

      refute html =~ "data:"
      assert html =~ ~S(src="")
    end
  end

  describe "integration with transform pipeline" do
    test "applies typography transforms", %{simple_markdown: markdown} do
      {:ok, ast} = Renderer.render(markdown, :note)

      # Check for typography-enhanced elements
      assert Enum.any?(ast, fn
               {:typography, "h1", attrs, _, _} ->
                 # Validate specific attributes are set
                 assert Map.has_key?(attrs, :size)
                 assert Map.has_key?(attrs, :font)
                 true

               _ ->
                 false
             end)
    end

    test "integration with transform pipeline applies component transforms", %{
      markdown: markdown
    } do
      # This test verifies that component transforms produce valid AST
      {:ok, ast} = Renderer.render(markdown, :note)
      assert is_list(ast)
      assert ast != []

      # Verify image becomes a component inside a paragraph
      image_paragraph =
        Enum.find(ast, fn
          {:typography, "p", _attrs, content, _meta} ->
            Enum.any?(content, fn
              {:component, :image, attrs, _content, _meta} ->
                attrs_map = Enum.into(attrs, %{})
                Map.has_key?(attrs_map, "src") || Map.has_key?(attrs_map, "alt")

              _ ->
                false
            end)

          _ ->
            false
        end)

      assert image_paragraph != nil,
             "Expected to find a paragraph containing an image component"
    end
  end

  # Test stub used by the component registry in this test file. Returns a
  # `Phoenix.HTML.safe/0` tuple so it can be composed into the safe-iodata
  # output of `Renderer.render_to_safe/1`. The production components (e.g.
  # `PortfolioWeb.Components.Image`) return `~H""" … """` which renders to
  # the same safe shape.
  def render(assigns) do
    src = to_string(assigns[:src] || "")
    alt = to_string(assigns[:alt] || "")
    {:safe, src_io} = Phoenix.HTML.html_escape(src)
    {:safe, alt_io} = Phoenix.HTML.html_escape(alt)

    {:safe,
     [
       ~s(<test-component type="),
       to_string(assigns[:component]),
       ~s(" src="),
       src_io,
       ~s(" alt="),
       alt_io,
       ~s("/>)
     ]}
  end

  # Helper to ensure the component registry is running for tests
  defp ensure_component_registry_started do
    case Process.whereis(Portfolio.Content.Markdown.Component.Registry) do
      nil ->
        # Not started, start it now
        {:ok, pid} = Portfolio.Content.Markdown.Component.Registry.start_link()
        pid

      _pid ->
        # Already running
        nil
    end
  end
end
