defmodule PortfolioWeb.Layouts do
  @moduledoc false
  use PortfolioWeb, :html
  alias PortfolioWeb.Router.Helpers, as: Routes
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
    current_locale = conn.assigns[:locale] || Application.get_env(:portfolio, :default_locale)
    current_path = Phoenix.Controller.current_path(conn)

    # Remove locale from the beginning of the path
    path_without_locale =
      current_path
      |> String.split("/", parts: 3)
      |> Enum.at(2, "")
      |> String.trim_leading("/")

    tags =
      @supported_locales
      |> Enum.map(fn locale ->
        locale_path = "/#{locale}/#{path_without_locale}"
        locale_url = Routes.url(conn) <> locale_path
        query_string = if conn.query_string != "", do: "?#{conn.query_string}", else: ""
        full_url = locale_url <> query_string

        ~s(<link rel="alternate" hreflang="#{locale}" href="#{full_url}" />)
      end)

    # Add x-default tag (usually pointing to the default locale or homepage)
    default_url = Routes.url(conn) <> "/"
    default_tag = ~s(<link rel="alternate" hreflang="x-default" href="#{default_url}" />)

    (tags ++ [default_tag])
    |> Enum.join("\n")
    |> Phoenix.HTML.raw()
  end
end
