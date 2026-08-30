defmodule Portfolio.Content.Markdown.Transforms.CodeBlockTest do
  use ExUnit.Case, async: true

  import Mox

  alias Portfolio.Content.Code.Tokenizer
  alias Portfolio.Content.Markdown.Transforms.CodeBlock

  setup :verify_on_exit!

  # Earmark's shape for ```elixir fenced code (the parser attaches
  # data-filename when the fence's info string carried one).
  defp fence(source, attrs) do
    {"pre", [], [{"code", attrs, [source], %{}}], %{}}
  end

  describe "apply/2" do
    test "a fenced block becomes a code-block component carrying classified code" do
      expect(Tokenizer.Mock, :classify, fn ":ok\n", "elixir" ->
        {:ok, ~s(<span class="tok-atom">:ok</span>\n)}
      end)

      ast = [fence(":ok\n", [{"class", "elixir"}])]

      assert {:ok, [node]} = CodeBlock.apply(ast, tokenizer: Tokenizer.Mock)

      assert {:component, :code_block, attrs, [], %{}} = node

      assert attrs == %{
               "code" => ~s(<span class="tok-atom">:ok</span>\n),
               "language" => "elixir",
               "filename" => nil
             }
    end

    test "the fence's filename rides along into the component" do
      expect(Tokenizer.Mock, :classify, fn _, _ -> {:ok, "classified"} end)

      ast = [
        fence(":ok\n", [{"class", "elixir"}, {"data-filename", "lib/foo.ex"}])
      ]

      assert {:ok, [{:component, :code_block, attrs, [], _}]} =
               CodeBlock.apply(ast, tokenizer: Tokenizer.Mock)

      assert attrs["filename"] == "lib/foo.ex"
    end

    test "a fence without a language still classifies (as plain) through the tokenizer" do
      expect(Tokenizer.Mock, :classify, fn "plain\n", nil ->
        {:ok, "plain\n"}
      end)

      ast = [fence("plain\n", [])]

      assert {:ok, [{:component, :code_block, attrs, [], _}]} =
               CodeBlock.apply(ast, tokenizer: Tokenizer.Mock)

      assert attrs["language"] == nil
      assert attrs["code"] == "plain\n"
    end

    test "a tokenizer failure degrades to plain escaped code — publishing is never blocked" do
      expect(Tokenizer.Mock, :classify, fn _, _ -> {:error, :engine_crashed} end)

      ast = [fence("x = <1>\n", [{"class", "elixir"}])]

      assert {:ok, [{:component, :code_block, attrs, [], _}]} =
               CodeBlock.apply(ast, tokenizer: Tokenizer.Mock)

      assert attrs["code"] == "x = &lt;1&gt;\n"
      refute attrs["code"] =~ "tok-"
    end

    test "inline code and the rest of the document pass through untouched" do
      ast = [
        {"h1", [], ["Title"], %{}},
        {"p", [], [{"code", [{"class", "inline"}], ["x = 1"], %{}}], %{}},
        {"blockquote", [], [{"p", [], ["quote"], %{}}], %{}}
      ]

      assert {:ok, ^ast} = CodeBlock.apply(ast, tokenizer: Tokenizer.Mock)
    end

    test "fenced blocks nested deeper in the document are still found" do
      expect(Tokenizer.Mock, :classify, fn ":ok\n", "elixir" ->
        {:ok, "classified"}
      end)

      ast = [
        {"div", [], [fence(":ok\n", [{"class", "elixir"}])], %{}}
      ]

      assert {:ok, [{"div", [], [{:component, :code_block, _, [], _}], %{}}]} =
               CodeBlock.apply(ast, tokenizer: Tokenizer.Mock)
    end
  end
end
