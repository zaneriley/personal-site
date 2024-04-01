defmodule PortfolioWeb.Layouts do
  @moduledoc false
  use PortfolioWeb, :html
  embed_templates "layouts/*"

  @supported_locales Application.compile_env(:portfolio, :supported_locales)

  # Function to construct the URL path for a given path and locale
  def locale_url(conn, locale, remaining_path) do
    remaining_path = String.trim_leading(remaining_path, "/")
    path_with_locale = "/#{locale}/#{remaining_path}"
    query_string = conn.query_string |> URI.decode_query()

    query_part =
      if query_string == %{}, do: "", else: "?#{URI.encode_query(query_string)}"

    final_url = "#{path_with_locale}#{query_part}"
    final_url
  end

  def hreflang_tags(conn) do
    {_, remaining_path} = PortfolioWeb.Plugs.SetLocale.extract_locale(conn)

    @supported_locales
    |> Enum.map_join("\n", fn locale ->
      locale_url = locale_url(conn, locale, remaining_path)
      ~s(<link rel="alternate" hreflang="#{locale}" href="#{locale_url}" />)
    end)
    |> Phoenix.HTML.raw()
  end
end
