defmodule Portfolio.Content.Code.Tokenizer.LumisTest do
  use ExUnit.Case, async: true

  alias Portfolio.Content.Code.Tokenizer

  @elixir_sample """
  defmodule Foo do
    @impl Bar
    def go(x) when is_map(x) do
      {:ok, n} = Map.fetch(x, :key)
      # a comment
      "str" <> to_string(n + 1.5)
    end
  end
  """

  describe "classify/2 with a known language" do
    test "classifies Elixir into the tok vocabulary" do
      assert {:ok, html} = Tokenizer.Lumis.classify(@elixir_sample, "elixir")

      assert html =~ "tok-keyword"
      assert html =~ "tok-atom"
      assert html =~ "tok-call"
      assert html =~ "tok-string"
      assert html =~ "tok-comment"
      assert html =~ "tok-number"
    end

    test "no vendor vocabulary leaks into the classified output" do
      assert {:ok, html} = Tokenizer.Lumis.classify(@elixir_sample, "elixir")

      refute html =~ "lumis"
      refute html =~ "data-line"
      refute html =~ ~s(class="line")
      refute html =~ "language-elixir"
      refute html =~ "keyword-function"
      refute html =~ "string-special-symbol"
      refute html =~ "<pre"
    end

    test "the text content survives classification exactly (the copy guarantee)" do
      assert {:ok, html} = Tokenizer.Lumis.classify(@elixir_sample, "elixir")

      assert text_content(html) == @elixir_sample
    end

    test "newlines are real newlines, so line counts match the source" do
      assert {:ok, html} = Tokenizer.Lumis.classify(@elixir_sample, "elixir")

      source_lines =
        @elixir_sample |> String.trim_trailing("\n") |> String.split("\n")

      output_lines =
        html
        |> text_content()
        |> String.trim_trailing("\n")
        |> String.split("\n")

      assert length(output_lines) == length(source_lines)
    end

    test "classifies the site's other languages" do
      assert {:ok, rust} =
               Tokenizer.Lumis.classify("fn main() { let x = 1; }", "rust")

      assert rust =~ "tok-keyword"

      assert {:ok, css} = Tokenizer.Lumis.classify(".a { color: red; }", "css")
      assert css =~ "tok-"

      assert {:ok, yaml} = Tokenizer.Lumis.classify("key: value\n", "yaml")
      assert yaml =~ "tok-"
    end
  end

  describe "classify/2 degrading gracefully" do
    test "an unknown language yields plain escaped code, never an error" do
      assert {:ok, html} =
               Tokenizer.Lumis.classify("x = <1>\n", "not-a-language")

      refute html =~ "tok-"
      assert text_content(html) == "x = <1>\n"
    end

    test "a missing language yields plain escaped code" do
      assert {:ok, html} = Tokenizer.Lumis.classify("plain text\n", nil)

      refute html =~ "tok-"
      assert text_content(html) == "plain text\n"
    end
  end

  # Strips tags and unescapes entities — what a browser's textContent (and the
  # copy button) reads back. Floki can't do this: its parser drops
  # whitespace-only text nodes between elements.
  defp text_content(html) do
    html
    |> String.replace(~r/<[^>]+>/, "")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    |> String.replace("&lbrace;", "{")
    |> String.replace("&rbrace;", "}")
    |> String.replace("&amp;", "&")
  end
end
