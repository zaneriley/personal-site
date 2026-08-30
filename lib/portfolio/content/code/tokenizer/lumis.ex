defmodule Portfolio.Content.Code.Tokenizer.Lumis do
  @moduledoc """
  Syntax classification via the Lumis tree-sitter engine (the package formerly
  named Autumn).

  ALL Lumis/tree-sitter vocabulary is contained here: the engine emits
  `<pre class="lumis">` wrapping per-line `<div class="line" data-line="N">`
  elements whose spans carry tree-sitter capture names (`keyword-function`,
  `string-special-symbol`, …). This module unwraps that structure into plain
  newline-separated HTML and maps the capture names onto the site's `tok-*`
  classes. Swapping the engine later means rewriting this file and nothing
  else.
  """

  @behaviour Portfolio.Content.Code.Tokenizer

  # Capture-name → tok-* class. Most-specific prefixes first: atoms arrive as
  # string-special-symbol and must not fall into the string bucket; call sites
  # arrive as function-call and must not fall into the (definition-site)
  # function bucket. Captures not listed here render unclassified (plain) —
  # vendor names never pass through.
  @capture_to_tok [
    {"string-special-symbol", "tok-atom"},
    {"function-call", "tok-call"},
    {"keyword", "tok-keyword"},
    {"string", "tok-string"},
    {"comment", "tok-comment"},
    {"function", "tok-function"},
    {"module", "tok-module"},
    {"type", "tok-type"},
    {"constant", "tok-attribute"},
    {"attribute", "tok-attribute"},
    {"operator", "tok-operator"},
    {"punctuation", "tok-punctuation"},
    {"number", "tok-number"}
  ]

  @line_pattern ~r{<div class="line" data-line="\d+">(.*?)</div>}s
  @span_class_pattern ~r{(<span class=")([a-z-]+)(")}

  @impl Portfolio.Content.Code.Tokenizer
  @spec classify(String.t(), String.t() | nil) ::
          {:ok, String.t()} | {:error, term()}
  def classify(source, nil) when is_binary(source) do
    # No language on the fence = plain code by definition; the engine has
    # nothing to add (and its option validation rejects nil).
    {:ok, source |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()}
  end

  def classify(source, language) when is_binary(source) do
    # The engine's only failure mode is raising (its success typing is
    # {:ok, binary()} — unknown languages come back as plaintext, not errors),
    # so match the ok assertively and let the rescue own failure: a NIF/engine
    # crash must never take content compilation down with it.
    {:ok, html} =
      Lumis.highlight(source, formatter: {:html_linked, language: language})

    classified =
      html
      |> unwrap_lines()
      |> map_capture_classes()
      |> match_trailing_newlines(source)

    {:ok, classified}
  rescue
    error -> {:error, error}
  end

  # The engine wraps output in <pre><code> and one div per line (each line's
  # text already ends in \n) — strip the chrome, keep the classified text.
  defp unwrap_lines(html) do
    @line_pattern
    |> Regex.scan(html, capture: :all_but_first)
    |> Enum.map_join("", &hd/1)
  end

  # Capture names map by longest-prefix; unmapped captures lose their class
  # entirely (plain text color) rather than leaking engine vocabulary.
  defp map_capture_classes(html) do
    Regex.replace(@span_class_pattern, html, fn _full, open, capture, close ->
      case tok_class(capture) do
        nil -> "<span"
        tok -> open <> tok <> close
      end
    end)
  end

  defp tok_class(capture) do
    Enum.find_value(@capture_to_tok, fn {prefix, tok} ->
      if String.starts_with?(capture, prefix), do: tok
    end)
  end

  # The engine appends its own final line; the source's trailing newlines are
  # the truth (copy must read back the exact source).
  defp match_trailing_newlines(html, source) do
    [trailing] = Regex.run(~r/\n*$/, source)
    String.trim_trailing(html, "\n") <> trailing
  end
end
