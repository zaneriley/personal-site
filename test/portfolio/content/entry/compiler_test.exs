defmodule Portfolio.Content.Entry.CompilerTest do
  use Portfolio.DataCase

  alias Portfolio.Content.Entry.Compiler
  alias Portfolio.Content.Entry.AstSerialization
  alias Portfolio.Content.Markdown.Renderer
  alias Portfolio.ContentFixtures
  alias Portfolio.Content.TranslationRepository

  describe "parse_to_ast/1" do
    test "successfully parses valid markdown" do
      content = "# Hello\n\nThis is a paragraph."

      assert {:ok, ast} = Compiler.parse_to_ast(content)
      assert is_list(ast)

      # The actual AST format may vary, but we can check for common elements
      assert ast != []
    end

    test "returns error for invalid content" do
      # Pass nil which now is handled explicitly
      assert {:error, _} = Compiler.parse_to_ast(nil)
    end
  end

  describe "process_ast/2" do
    test "processes an AST without modifying it (initial implementation)" do
      ast = [
        %{
          "type" => "element",
          "tag" => "p",
          "attrs" => %{},
          "children" => [
            %{"type" => "text", "text" => "Hello, world!"}
          ]
        }
      ]

      processed_ast = Compiler.process_ast(ast)
      assert processed_ast == ast
    end
  end

  describe "render_ast/2" do
    test "renders AST to HTML" do
      # Use a simplified AST format that matches what the tests expect
      ast = [{"p", [], ["Hello, world!"], %{}}]

      html = Compiler.render_ast(ast)
      assert is_binary(html)
      assert html =~ "<p>"
      assert html =~ "Hello, world!"
      assert html =~ "</p>"
    end
  end

  describe "compile/2" do
    test "compiles markdown content to HTML" do
      content = "# Hello\n\nThis is a paragraph."

      assert {:ok, result} = Compiler.compile(content)
      assert Map.has_key?(result, :ast)
      assert Map.has_key?(result, :compiled_content)

      assert is_list(result.ast)
      assert is_binary(result.compiled_content)

      # Check the compiled content contains expected HTML
      assert result.compiled_content =~ "<h1>"
      assert result.compiled_content =~ "Hello"
      assert result.compiled_content =~ "<p>"
      assert result.compiled_content =~ "This is a paragraph"
    end

    test "returns error when compilation fails" do
      # Pass nil to cause a compilation error
      assert {:error, _} = Compiler.compile(nil)
    end
  end

  describe "compile_translations/2" do
    test "compiles content with translations" do
      # First, make sure we clear the cache to avoid test pollution
      Portfolio.DataCase.clear_cache()

      # Create a note with translations
      note = ContentFixtures.note_fixture()

      # Add a Japanese translation with explicit content and title
      TranslationRepository.create_or_update_translations(note, "ja", %{
        "title" => "日本語タイトル",
        "content" => "これは日本語のコンテンツです。"
      })

      # Reload note to get the most up-to-date data
      note = Portfolio.Repo.get!(note.__struct__, note.id)

      # Compile with translations
      assert {:ok, result} = Compiler.compile_translations(note)

      # Verify we have compiled translations
      assert Map.has_key?(result, :translations)
      assert Map.has_key?(result, :primary_ast)

      # Verify translations map structure
      translations = result.translations
      assert Map.has_key?(translations, "en")
      assert Map.has_key?(translations, "ja")

      # Check English (original) content
      en_compiled = translations["en"]
      assert en_compiled.source == :original
      assert is_binary(en_compiled.compiled_content)

      # Check Japanese (translated) content
      ja_compiled = translations["ja"]
      assert ja_compiled.source == :translation
      assert is_binary(ja_compiled.compiled_content)
    end

    test "handles content without translations" do
      # First, make sure we clear the cache to avoid test pollution
      Portfolio.DataCase.clear_cache()

      # Create a note without translations (skip default translation creation)
      note = ContentFixtures.note_fixture(%{}, skip_translations: true)

      # Compile (it should still have the original locale)
      assert {:ok, result} = Compiler.compile_translations(note)

      # Check translations
      translations = result.translations
      assert Map.has_key?(translations, "en")
      refute Map.has_key?(translations, "ja")
    end
  end

  describe "deserialize_and_process_ast/2" do
    test "deserializes and processes stored AST" do
      # Create an AST and serialize it
      ast = [
        %{
          "type" => "element",
          "tag" => "p",
          "attrs" => %{},
          "children" => [
            %{"type" => "text", "text" => "Hello, world!"}
          ]
        }
      ]

      serialized_ast = AstSerialization.serialize_ast(ast)

      # Deserialize and process
      processed_ast = Compiler.deserialize_and_process_ast(serialized_ast)

      # Verify the result
      assert is_list(processed_ast)
      assert processed_ast != []
    end

    test "handles nil input" do
      assert [] = Compiler.deserialize_and_process_ast(nil)
    end
  end

  describe "fenced code through compile -> store -> render (end to end)" do
    setup do
      case Portfolio.Content.Markdown.Component.Registry.register(
             :code_block,
             PortfolioWeb.Components.CodeBlock,
             custom_function: :code_block
           ) do
        :ok -> :ok
        {:error, :already_registered} -> :ok
      end
    end

    test "a fenced block bakes classified code at compile and renders chrome from storage" do
      markdown = """
      ```elixir lib/push_search/accounts.ex
      defmodule Foo do
        :ok
      end
      ```
      """

      assert {:ok, %{ast: ast}} = Compiler.compile(markdown)

      # Baked at compile: the fence is now a component node carrying tok-* HTML.
      assert [{:component, :code_block, attrs, [], _}] = ast
      assert attrs["language"] == "elixir"
      assert attrs["filename"] == "lib/push_search/accounts.ex"
      assert attrs["code"] =~ "tok-keyword"
      assert attrs["code"] =~ "tok-atom"

      # The DB round trip (storage is JSON-shaped) preserves the baked node.
      restored =
        ast
        |> AstSerialization.serialize_ast()
        |> Jason.encode!()
        |> Jason.decode!()
        |> AstSerialization.deserialize_ast()

      # Read-path processing is a no-op on already-baked content.
      assert Compiler.process_ast(restored) == restored

      # Render is pure markup assembly: chrome + the baked spans, no tokenizing.
      html = Renderer.render_html(restored)
      assert html =~ "code-block"
      assert html =~ "tok-keyword"
      assert html =~ "accounts.ex"
      assert html =~ "lib/push_search/"
    end

    test "a fence in an unknown language compiles to a plain uncolored code block" do
      markdown = """
      ```nope-lang
      x = 1
      ```
      """

      assert {:ok, %{ast: ast}} = Compiler.compile(markdown)
      assert [{:component, :code_block, attrs, [], _}] = ast
      refute attrs["code"] =~ "tok-"

      html = Renderer.render_html(ast)
      assert html =~ "code-block"
      assert html =~ "x = 1"
    end
  end
end
