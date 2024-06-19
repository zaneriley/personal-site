defmodule PortfolioWeb.Plugs.LocaleRedirection do
  @moduledoc """
  A plug that handles locale-based redirections for incoming requests.

  This plug checks the initial segment of the request path to determine if it corresponds to a supported locale. If the locale is not supported, and it is not an empty string, the plug responds with a 404 status code. If the path does not contain a locale, the plug redirects the user to a path that includes their preferred locale, which is determined by the user's session or the application's default locale.

  The redirection is particularly useful for root paths, ensuring that users are always served content in their preferred or default locale.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]
  require Logger

  @supported_locales Application.compile_env(:portfolio, :supported_locales)
  @default_locale Application.compile_env(:portfolio, :default_locale)

  def init(default), do: default

  def call(conn, _default) do
    Logger.debug("LocaleRedirection: Starting redirection logic.")
    {locale_from_url, remaining_path} = extract_locale_from_path(conn.request_path)
    Logger.debug("LocaleRedirection: Extracted locale '#{locale_from_url}' and path '#{remaining_path}'.")

    user_locale = conn.assigns[:user_locale] || get_session(conn, "user_locale") || @default_locale
    Logger.debug("LocaleRedirection: Using user locale '#{user_locale}'.")

    cond do
      # Case 1: Supported Locale in URL
      locale_from_url in @supported_locales ->
        log_supported_locale(locale_from_url)
        conn

      # Case 2: Unsupported Locale in URL
      locale_from_url != "" ->
        if is_valid_route?(conn, remaining_path) do
          log_valid_route(remaining_path)
          conn
        else
          log_unsupported_locale(locale_from_url)
          send_resp(conn, 404, "Not Found") |> halt()
        end

        true ->
          redirect_path = build_path_with_locale(remaining_path, user_locale)
          if is_valid_route?(conn, redirect_path) do
            log_redirect(redirect_path)
            redirect(conn, to: redirect_path) |> halt()
          else
            send_resp(conn, 404, "Not Found") |> halt()
          end
    end
  end

  defp is_valid_route?(conn, path) do
    Phoenix.Router.route_info(PortfolioWeb.Router, conn.method, path, conn.host) != :error
  end

  defp log_valid_route(path) do
    Logger.debug(
      "LocaleRedirection: Valid route found for path #{path}, allowing request to proceed."
    )
  end

  defp log_supported_locale(locale),
    do:
      Logger.debug(
        "LocaleRedirection: Supported locale #{locale} found in URL."
      )

  defp log_unsupported_locale(locale),
    do:
      Logger.info(
        "LocaleRedirection: Unsupported locale #{locale} found in URL, responding with 404."
      )

  defp log_redirect(redirect_path),
    do: Logger.info("LocaleRedirection: Redirecting to #{redirect_path}")

    defp build_path_with_locale("/", user_locale), do: "/#{locale_to_redirect(user_locale)}/"
    defp build_path_with_locale(request_path, user_locale), do: "/#{locale_to_redirect(user_locale)}#{request_path}"

  defp locale_to_redirect(user_locale) when user_locale in @supported_locales,
    do: user_locale

  defp locale_to_redirect(_), do: @default_locale

  defp extract_locale_from_path(path) do
    [_, possible_locale | remaining_parts] = String.split(path, "/")
    if possible_locale in @supported_locales do
      {String.downcase(possible_locale), "/" <> Enum.join(remaining_parts, "/")}
    else
      {"", path}
    end
  end
end
