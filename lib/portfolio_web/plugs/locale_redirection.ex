defmodule PortfolioWeb.Plugs.LocaleRedirection do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]
  require Logger

  @supported_locales Application.compile_env(:portfolio, :supported_locales)
  @default_locale Application.compile_env(:portfolio, :default_locale)

  def init(default), do: default

  def call(conn, _default) do
    {locale_from_url, remaining_path} = extract_locale_from_path(conn.request_path)
    user_locale = conn.assigns[:user_locale] || get_session(conn, "user_locale") || @default_locale

    case {locale_from_url, remaining_path} do
      {locale, _} when locale in @supported_locales ->
        Logger.debug("LocaleRedirection: Supported locale #{locale} found in URL.")
        conn

      {locale, _} when locale not in @supported_locales and locale != "" ->
        Logger.info("LocaleRedirection: Unsupported locale #{locale} found in URL, responding with 404.")
        conn
        |> send_resp(404, "Not Found")
        |> halt()

      {"", _} ->
        redirect_path = determine_redirect_path(conn.request_path, user_locale, remaining_path)
        Logger.info("LocaleRedirection: Redirecting to #{redirect_path}")
        conn
        |> redirect(to: redirect_path)
        |> halt()
    end
  end

  defp determine_redirect_path(request_path, user_locale, _remaining_path) do
    # If the request path is the root path, redirect to the user's locale root
    # or to the default locale if the user's locale is not supported.
    if request_path == "/" do
      locale_to_redirect = if user_locale in @supported_locales, do: user_locale, else: @default_locale
      "/#{locale_to_redirect}/"
    else
      request_path
    end
  end

  defp extract_locale_from_path(path) do
    [_, possible_locale | remaining_parts] = String.split(path, "/")
    {possible_locale, "/" <> Enum.join(remaining_parts, "/")}
  end
end
