defmodule PortfolioWeb.FeedXML do
  @moduledoc """
  Serializes feed entries to Atom 1.0 — the wire edge where protocol
  vocabulary lives (`_PROJECT_DOCS/feeds-spec.md`, Entry mapping).

  Three invariants this module owns:
  - entry ids are locale-scoped tag URIs from the stable DB id, never slugs;
  - every URL is absolute, including inside the embedded content HTML
    (absolutized first, then XML-escaped — EEx does not escape for us);
  - content renders from the baked AST when present (the publish-time
    pipeline's output), compiling only as fallback for legacy rows and
    translations.
  """

  require EEx

  alias Portfolio.Content.Entry.Compiler
  alias Portfolio.Content.Markdown.Renderer
  alias PortfolioWeb.SiteOrigin

  # tag URI authority + minting year — fixed at first publication, never
  # derived from the clock (ids must not drift), see RFC 4151.
  @tag_authority "zaneriley.com,2026"

  EEx.function_from_file(
    :def,
    :render_feed,
    Path.join(__DIR__, "feed_xml/feed.xml.eex"),
    [:assigns]
  )

  @doc "Builds the template assigns for one entry, localized."
  @spec entry_assigns(struct(), String.t()) :: map()
  def entry_assigns(entry, locale) do
    translations = Map.get(entry, :translations) || %{}

    %{
      id: tag_uri(entry, locale),
      title: localized(entry, translations, :title),
      url: SiteOrigin.absolute_url(entry_path(entry, locale)),
      published: rfc3339(entry.published_at),
      updated: rfc3339(latest_of(entry.updated_at, entry.published_at)),
      summary: localized(entry, translations, :introduction),
      content_html:
        entry
        |> content_html(translations, locale)
        |> absolutize_urls(SiteOrigin.absolute_url(entry_path(entry, locale)))
    }
  end

  @doc """
  Escapes text/HTML for embedding in the XML document. The named entities
  Phoenix emits (`&amp; &lt; &gt; &quot; &#39;`) are all XML-valid.
  """
  @spec xml_escape(String.t() | nil) :: String.t()
  def xml_escape(nil), do: ""

  def xml_escape(text) do
    text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
  end

  # ── id ──
  defp tag_uri(%module{} = entry, locale) do
    "tag:#{@tag_authority}:#{module.translatable_type()}/#{entry.id}/#{locale}"
  end

  # ── localized fields ──
  defp localized(entry, translations, field) do
    Map.get(translations, to_string(field)) || Map.get(entry, field)
  end

  # Canonical-locale content renders from the baked AST (publish-time
  # pipeline output); a missing AST falls back to compiling, the same
  # degradation the pages use. Translated content is stored as markdown
  # and compiles at render.
  defp content_html(%{locale: locale} = entry, _translations, locale) do
    case entry.stored_ast do
      ast when is_list(ast) and ast != [] ->
        ast |> Compiler.deserialize_and_process_ast() |> Renderer.render_html()

      _ ->
        compile_markdown(entry.content)
    end
  end

  defp content_html(entry, translations, _locale) do
    compile_markdown(Map.get(translations, "content") || entry.content)
  end

  defp compile_markdown(nil), do: ""

  defp compile_markdown(markdown) do
    case Compiler.compile(markdown) do
      # the template escapes content exactly once — the fallback is plain
      # text, never pre-escaped (double-escaping showed readers &lt;)
      {:ok, %{ast: ast}} -> Renderer.render_html(ast)
      {:error, _} -> markdown
    end
  end

  # ── URLs ──
  defp entry_path(%module{} = entry, locale) do
    section =
      case module.translatable_type() do
        "note" -> "note"
        "case_study" -> "case-study"
      end

    "/#{locale}/#{section}/#{entry.url}"
  end

  # Every relative href/src — root-relative, bare, ./ and ../ — resolves
  # against the entry's own canonical URL (what a browser would do on the
  # page); absolute, protocol-relative, fragment and non-http schemes pass
  # through. Readers resolve nothing.
  defp absolutize_urls(html, base_url) do
    Regex.replace(~r{((?:href|src)=)(["'])(.*?)\2}s, html, fn full,
                                                              attr,
                                                              quote,
                                                              value ->
      if leave_as_is?(value) do
        full
      else
        attr <> quote <> to_string(URI.merge(base_url, value)) <> quote
      end
    end)
  end

  defp leave_as_is?(value) do
    value == "" or
      String.starts_with?(value, ["#", "//"]) or
      String.contains?(value, ":")
  end

  # ── dates ──
  defp rfc3339(%DateTime{} = dt),
    do: dt |> DateTime.truncate(:second) |> DateTime.to_iso8601()

  defp rfc3339(%NaiveDateTime{} = ndt),
    do: ndt |> DateTime.from_naive!("Etc/UTC") |> rfc3339()

  defp latest_of(nil, fallback), do: fallback

  defp latest_of(updated, published) do
    # `updated` may legitimately precede `published` in the DB (rows update
    # before publication); Atom consumers reject that ordering.
    if compare(updated, published) == :lt, do: published, else: updated
  end

  defp compare(%DateTime{} = a, b), do: DateTime.compare(a, to_datetime(b))

  defp compare(%NaiveDateTime{} = a, b),
    do: DateTime.compare(to_datetime(a), to_datetime(b))

  defp to_datetime(%DateTime{} = dt), do: dt

  defp to_datetime(%NaiveDateTime{} = ndt),
    do: DateTime.from_naive!(ndt, "Etc/UTC")
end
