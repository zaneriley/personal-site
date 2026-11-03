defmodule PortfolioWeb.Layouts do
  @moduledoc false
  use PortfolioWeb, :html
  use Gettext, backend: PortfolioWeb.Gettext
  embed_templates "layouts/*"

  @supported_locales Application.compile_env(:portfolio, :supported_locales)

  def remove_locale_from_path(path) do
    case String.split(path, "/", parts: 3) do
      ["", locale, rest] when locale in @supported_locales -> "/#{rest}"
      ["", locale] when locale in @supported_locales -> "/"
      _ -> path
    end
  end

  @doc """
  The same page in `locale`: swaps the locale prefix, or adds one.

      localized_path("/en/work/foo", "ja") #=> "/ja/work/foo"
      localized_path("/en", "ja")          #=> "/ja"

  The one place a cross-language address is built; the header's language
  switch and the `hreflang` alternates both call it.
  """
  @spec localized_path(String.t(), String.t()) :: String.t()
  def localized_path(path, locale) do
    case remove_locale_from_path(path) do
      "/" -> "/#{locale}"
      rest -> "/#{locale}#{rest}"
    end
  end

  # Alternates point at canonical pages, so they carry no query string.
  def hreflang_tags(conn) do
    base_url = url(conn, ~p"/") |> String.trim_trailing("/")

    alternates =
      for locale <- @supported_locales do
        {locale, base_url <> localized_path(conn.request_path, locale)}
      end

    (alternates ++ [{"x-default", base_url <> "/"}])
    |> Enum.map_join("\n", fn {hreflang, href} ->
      ~s(<link rel="alternate" hreflang="#{hreflang}" href="#{escape(href)}" />)
    end)
    |> Phoenix.HTML.raw()
  end

  defp escape(text),
    do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
end
