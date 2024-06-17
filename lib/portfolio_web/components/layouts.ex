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
    {user_locale, remaining_path} =
      PortfolioWeb.Plugs.SetLocale.extract_locale(conn)

    tags =
      @supported_locales
      |> Enum.map(fn locale ->
        locale_url =
          PortfolioWeb.Router.Helpers.url(conn) <>
            locale_url(conn, locale, remaining_path)

        ~s(<link rel="alternate" hreflang="#{locale}" href="#{locale_url}" />)
      end)

    default_url = PortfolioWeb.Router.Helpers.url(conn)

    default_tag =
      ~s(<link rel="alternate" hreflang="x-default" href="#{default_url}" />)

    (tags ++ [default_tag])
    |> Enum.join("\n")
    |> Phoenix.HTML.raw()
  end
end
