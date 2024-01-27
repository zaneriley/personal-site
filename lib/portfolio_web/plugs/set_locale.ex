defmodule PortfolioWeb.Plugs.SetLocale do
  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn
  import PortfolioWeb.Gettext
  alias PortfolioWeb, as: PW
  require Logger

  @supported_locales ["en", "ja"] # Define your supported locales
  @default_locale "en"
  @static_paths PW.static_paths()



  # Add a structured logging function
  defp log(level, message, metadata \\ %{}) do
    Logger.log(level, fn ->
      Map.put(metadata, :message, message)
      |> Jason.encode!() # Ensure you have the Jason library as a dependency
    end)
  end

  def init(default), do: default

  def call(conn, _default) do
    Logger.debug("SetLocale: Processing request", %{
      path: conn.request_path,
      action: "Determining if static asset or locale"
    })
    if is_static_asset?(conn.request_path) do
      Logger.debug("Static asset request bypassing locale processing", %{path: conn.request_path})
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

      Logger.debug("SetLocale: Detected user_locale", %{
        user_locale: user_locale,
        path: conn.request_path
      })

      set_gettext_locale(user_locale)

      # Redirect if the locale from the URL is unsupported or not present
      # If the first path segment is not a supported locale, pass through the connection
      # This allows the router to handle the path and potentially return a 404
      if locale_from_url not in @supported_locales do
        Logger.debug("SetLocale: Path is not a recognized locale, passing through", %{
          path: conn.request_path,
          detected_locale: user_locale,
          locale_from_url: locale_from_url
        })
        conn = conn |> put_session("user_locale", user_locale)
      else
        # If the locale is supported, check if we need to redirect (for example, if the locale was detected from the session or headers)
        if locale_from_url != user_locale do
          redirect_path = "/#{user_locale}#{remaining_path}"
          Logger.info("SetLocale: Locale redirect", %{
            from_path: conn.request_path,
            to_path: redirect_path,
            reason: "Locale change detected"
          })
          conn = conn
            |> put_session("user_locale", user_locale)
            |> redirect(to: redirect_path)
          halt(conn)
        end
      end
      # Log the locale setting action
      Logger.debug("SetLocale:  Locale set", %{
        locale: user_locale,
        path: conn.request_path
      })
      conn
      |> put_session("user_locale", user_locale)
    end
  end

  defp is_static_asset?(path) do
    @static_paths
    |> Enum.any?(fn static_path ->
        Regex.match?(~r/^\/#{static_path}.*\.(png|jpg|jpeg|svg|ico)$/, path)
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
