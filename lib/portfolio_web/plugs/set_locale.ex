defmodule PortfolioWeb.Plugs.SetLocale do
  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn
  import PortfolioWeb.Gettext
  alias PortfolioWeb, as: PW
  require Logger

  @supported_locales ["en", "ja"] # Define your supported locales
  @default_locale "en"
  @static_paths PW.static_paths()


  def init(default), do: default

  def call(conn, _default) do
    if is_static_asset?(conn.request_path) do
      conn
    else
      {locale_from_url, remaining_path} = extract_locale_from_path(conn.request_path)

      # # Handle root path ("/") and redirect to default locale if needed
      # if remaining_path == "" do
      #   remaining_path = "/"
      # end

      user_locale =
        cond do
          locale_from_url in @supported_locales -> locale_from_url
          get_session(conn, "user_locale") -> get_session(conn, "user_locale")
          get_preferred_language(conn) in @supported_locales -> get_preferred_language(conn)
          true -> @default_locale
        end

      Logger.debug("Detected user_locale: #{user_locale}")

      set_gettext_locale(user_locale)

      # Redirect if the locale from the URL is unsupported or not present
      if locale_from_url not in @supported_locales do
        redirect_path = "/#{user_locale}#{remaining_path}"
        conn = conn
          |> put_session("user_locale", user_locale)
          |> redirect(to: redirect_path)
        halt(conn)
      end

      conn
      |> put_session("user_locale", user_locale)
    end
  end

  defp is_static_asset?(path) do
    @static_paths
    |> Enum.any?(fn static_path ->
        Regex.match?(~r/^\/#{static_path}(-\d*x\d*)?\.(png|jpg|jpeg|svg|ico)$/, path)
    end)
  end


  defp parse_accept_language_header(header) do
    header
    |> String.split(",")
    |> Enum.map(&String.split(&1, ";"))
    |> List.first()
    |> List.first()
    |> String.downcase()
    |> handle_language_subtags()
  end

  defp handle_language_subtags(language_tag) do
    case String.split(language_tag, "-") do
      ["en" | _] -> "en"
      ["ja" | _] -> "ja"
      _ -> @default_locale
    end
  end

  defp get_preferred_language(conn) do
    conn
    |> Plug.Conn.get_req_header("accept-language")
    |> List.first()
    |> parse_accept_language_header()
  end

  defp extract_locale_from_path(path) do
    [_, possible_locale | remaining_parts] = String.split(path, "/")
    {possible_locale, "/" <> Enum.join(remaining_parts, "/")}
  end

  defp set_gettext_locale(locale) do
    case locale do
      "en" -> Gettext.put_locale(PortfolioWeb.Gettext, "en")
      "ja" -> Gettext.put_locale(PortfolioWeb.Gettext, "ja") # Ensure correct mapping here
      _    -> Gettext.put_locale(PortfolioWeb.Gettext, "en") # default or 404
    end

    Logger.debug("Set locale for Gettext: #{Gettext.get_locale(PortfolioWeb.Gettext)}")
  end
end
