defmodule Portfolio.Content.Code.Tokenizer do
  @moduledoc """
  The boundary between source code and its syntax classification.

  A tokenizer turns source code into classified HTML: the same text, with
  token spans carrying the site's `tok-*` classes (the contract defined in
  `assets/css/_code.css`). Implementations own the translation from their
  engine's vocabulary into `tok-*` — no engine vocabulary may leak through
  this boundary, and the text content must survive classification exactly
  (the copy button reads it back).

  Classification is enhancement, not a dependency: an unknown or missing
  language yields plain escaped code as `{:ok, html}`, and `{:error, reason}`
  is reserved for engine failures. Callers degrade to plain code on error —
  publishing is never blocked by highlighting.
  """

  @doc """
  Classifies source code, returning HTML with `tok-*` token spans.

  The `language` is a fence-info-string name (e.g. `"elixir"`, `"rust"`);
  `nil` or an unknown name yields plain escaped code.
  """
  @callback classify(source :: String.t(), language :: String.t() | nil) ::
              {:ok, String.t()} | {:error, term()}
end
