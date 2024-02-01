defmodule PortfolioWeb.Plugs.SetLocale do
  import Plug.Conn
  alias PortfolioWeb, as: PW
  require Logger

  @supported_locales Application.compile_env!(:portfolio, :supported_locales)
  @default_locale Application.compile_env(:portfolio, :default_locale)
  @static_paths PW.static_paths()

  def init(default), do: default

  def call(conn, _default) do
    if is_static_asset?(conn.request_path) do
      conn
    else
      locale_data = extract_locale(conn)
      set_locale(conn, locale_data)
    end
  end


  defp extract_locale(conn) do
    {locale_from_url, remaining_path} = extract_locale_from_path(conn.request_path)
    accept_language = get_preferred_language(conn)
    Logger.debug("Accept-Language header: #{accept_language}")
    user_locale =
      cond do
        locale_from_url in @supported_locales -> locale_from_url
        get_session(conn, "user_locale") -> get_session(conn, "user_locale")
        accept_language in @supported_locales -> accept_language
        true -> @default_locale
      end
    {user_locale, remaining_path}
  end

  defp set_locale(conn, {user_locale, _remaining_path}) do
    Gettext.put_locale(PW.Gettext, user_locale)
    Logger.debug("Set locale for Gettext: #{Gettext.get_locale(PW.Gettext)}")
    conn
    |> put_session("user_locale", user_locale)
    |> assign(:user_locale, user_locale)
    |> assign(:supported_locales, @supported_locales)
    |> put_resp_header("content-language", user_locale)
  end

  defp is_static_asset?(path) do
    @static_paths
    |> Enum.any?(fn static_path ->
        Regex.match?(~r/^\/#{static_path}.*\.(png|jpg|jpeg|svg|ico)$/, path)
    end)
  end

  defp extract_locale_from_path(path) do
    [_, possible_locale | remaining_parts] = String.split(path, "/")
    {possible_locale, "/" <> Enum.join(remaining_parts, "/")}
  end

  defp get_preferred_language(conn) do
    conn
    |> get_req_header("accept-language")
    |> List.first()
    |> parse_accept_language_header()
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
    language_primary_tag = String.split(language_tag, "-") |> List.first()
    case language_primary_tag do
      tag when tag in @supported_locales -> tag
      _ -> @default_locale
    end
  end
end
