defmodule Portfolio.Content.Markdown.Transforms.CodeBlock do
  @moduledoc """
  Rewrites fenced code blocks into code-block component nodes, classifying the
  source at content-compile time.

  Earmark parses a fence into `{"pre", _, [{"code", attrs, [source]}]}` — the
  language rides in the code's `class` attr and the parser attaches the fence's
  filename (when its info string carried one) as `data-filename`. This
  transform runs the source through the tokenizer (see
  `Portfolio.Content.Code.Tokenizer`) and emits
  `{:component, :code_block, attrs, [], meta}`, so the classified HTML is
  baked into the stored AST once at publish time — request-time rendering is
  pure component markup around it.

  A tokenizer failure degrades to plain escaped code: highlighting is
  enhancement, and publishing is never blocked by it. Attr keys are strings so
  the node round-trips DB serialization unchanged.
  """

  alias Portfolio.Content.Code.Tokenizer

  @doc """
  Walks the AST, rewriting every fenced code block.

  ## Options

  - `:tokenizer` - the `Tokenizer` implementation (defaults to the configured
    `:code_tokenizer`, falling back to `Tokenizer.Lumis`)
  """
  @spec apply(list(), keyword()) :: {:ok, list()}
  def apply(ast, opts \\ []) when is_list(ast) do
    tokenizer =
      Keyword.get_lazy(opts, :tokenizer, fn ->
        Application.get_env(:portfolio, :code_tokenizer, Tokenizer.Lumis)
      end)

    {:ok, walk(ast, tokenizer)}
  end

  defp walk(nodes, tokenizer) when is_list(nodes) do
    Enum.map(nodes, &walk_node(&1, tokenizer))
  end

  defp walk_node(
         {"pre", _attrs, [{"code", code_attrs, [source], _}], meta},
         tokenizer
       )
       when is_binary(source) do
    language = attr_value(code_attrs, "class")
    filename = attr_value(code_attrs, "data-filename")

    attrs = %{
      "code" => classify(tokenizer, source, language),
      "language" => language,
      "filename" => filename
    }

    {:component, :code_block, attrs, [], meta}
  end

  defp walk_node({tag, attrs, children, meta}, tokenizer)
       when is_list(children) do
    {tag, attrs, walk(children, tokenizer), meta}
  end

  defp walk_node(other, _tokenizer), do: other

  defp classify(tokenizer, source, language) do
    case tokenizer.classify(source, language) do
      {:ok, classified} ->
        classified

      {:error, _reason} ->
        # Highlighting is enhancement — degrade to plain escaped code.
        source |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    end
  end

  defp attr_value(attrs, key) do
    Enum.find_value(attrs, fn
      {^key, value} -> value
      _ -> nil
    end)
  end
end
