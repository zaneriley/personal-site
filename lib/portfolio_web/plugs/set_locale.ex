defmodule PortfolioWeb.Plugs.SetLocale do
  @moduledoc """
  A plug that sets the locale for the connection.

  This plug determines the user's preferred locale by examining various sources in the following order:
  1. The URL path segment (e.g., '/en/some/path')
  2. The user's session, if previously set
  3. The 'Accept-Language' HTTP header
  4. The application's default locale

  If a locale is found, it is set for the connection and used by the Gettext module for translations. Additionally, the locale is stored in the user's session and sent back in the 'Content-Language' HTTP response header.

  Static assets are not affected by this plug, as their paths are matched against predefined static paths and served without setting a locale.
  """
  import Plug.Conn
  require Logger

  @telemetry_prefix [:portfolio, :plug, :set_locale]
  @supported_locales Application.compile_env!(:portfolio, :supported_locales)
  @default_locale Application.compile_env(:portfolio, :default_locale)
  @static_paths PortfolioWeb.static_paths()

  @type locale :: String.t()
  @type path :: String.t()
  @type locale_source :: :url | :session | :accept_language | :default

  @spec log(atom(), String.t(), keyword()) :: :ok
  defp log(level, message, metadata \\ []) do
    Logger.log(level, fn -> "[SetLocale] #{message}" end, metadata)
  end

  @spec init(any()) :: any()
  def init(default), do: default

  @doc """
  Calls the plug to set the locale for the connection.

  If the request is for a static asset, it passes through without modification.
  Otherwise, it extracts the locale and sets it for the connection.
  """
  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, _default) do
    start_time = System.monotonic_time()

    normalized_path = normalize_path(conn.request_path)
    conn = %{conn | request_path: normalized_path}

    result =
      if static_asset?(normalized_path) do
        log(:debug, "Static asset detected, skipping locale setting",
          path: normalized_path
        )

        conn
      else
        locale_data = extract_locale(conn)
        set_locale(conn, locale_data)
      end

    duration = System.monotonic_time() - start_time

    :telemetry.execute(
      @telemetry_prefix ++ [:call],
      %{duration: duration},
      %{conn: conn}
    )

    result
  end

  @doc """
  Extracts the locale from the connection.

  It checks the URL, session, and Accept-Language header to determine the user's preferred locale.
  """
  @spec extract_locale(Plug.Conn.t()) :: {locale(), path()}
  def extract_locale(conn) do
    start_time = System.monotonic_time()

    {locale_from_url, remaining_path} =
      extract_locale_from_path(conn.request_path)

    accept_language = get_preferred_language(conn)
    session_locale = get_session(conn, "user_locale")

    user_locale =
      cond do
        locale_from_url in @supported_locales -> locale_from_url
        session_locale in @supported_locales -> session_locale
        accept_language in @supported_locales -> accept_language
        true -> @default_locale
      end

    locale_source =
      determine_locale_source(
        user_locale,
        locale_from_url,
        session_locale,
        accept_language
      )

    log(:info, "Locale extracted",
      event: :locale_extracted,
      locale: user_locale,
      locale_source: locale_source,
      url_locale: locale_from_url,
      session_locale: session_locale,
      accept_language: accept_language,
      path: remaining_path
    )

    duration = System.monotonic_time() - start_time

    :telemetry.execute(
      @telemetry_prefix ++ [:extract_locale],
      %{duration: duration},
      %{conn: conn, locale: user_locale, source: locale_source}
    )

    {user_locale, remaining_path}
  end


  # Sets the locale for the connection.

  # It updates the Gettext locale, stores the locale in the session,
  # assigns it to the connection, and sets the Content-Language header.

  @spec set_locale(Plug.Conn.t(), {locale(), path()}) :: Plug.Conn.t()
  defp set_locale(conn, {user_locale, remaining_path}) do
    start_time = System.monotonic_time()

    result =
      case Phoenix.Router.route_info(
             PortfolioWeb.Router,
             conn.method,
             remaining_path,
             conn.host
           ) do
        %{} ->
          Gettext.put_locale(PortfolioWeb.Gettext, user_locale)

          log(:debug, "Set locale for Gettext", locale: user_locale)

          conn
          |> put_session("user_locale", user_locale)
          |> assign(:user_locale, user_locale)
          |> assign(:supported_locales, @supported_locales)
          |> put_resp_header("content-language", user_locale)

        :error ->
          log(:warning, "Invalid route after setting locale",
            path: remaining_path
          )

          conn
      end

    duration = System.monotonic_time() - start_time

    :telemetry.execute(
      @telemetry_prefix ++ [:set_locale],
      %{duration: duration},
      %{conn: conn, locale: user_locale}
    )

    result
  end


  # Determines if the given path is for a static asset.

  @spec static_asset?(path()) :: boolean()
  defp static_asset?(path) do
    @static_paths
    |> Enum.any?(fn static_path ->
      Regex.match?(~r/^\/#{static_path}.*\.(png|jpg|jpeg|svg|ico)$/, path)
    end)
  end


  # Extracts the locale from the given path.

  @spec extract_locale_from_path(path()) :: {locale(), path()}
  defp extract_locale_from_path(path) do
    log(:debug, "Extracting locale from path", path: path)

    case String.split(path, "/", parts: 2) do
      ["", possible_locale | _] when possible_locale in @supported_locales ->
        remaining_path =
          "/" <> (path |> String.split("/", parts: 3) |> Enum.at(2, ""))

        log(:debug, "Extracted locale from path",
          locale: possible_locale,
          remaining_path: remaining_path
        )

        {possible_locale, remaining_path}

      _ ->
        log(:debug, "No valid locale found in path", path: path)
        {"", path}
    end
  end


  # Gets the preferred language from the Accept-Language header.

  @spec get_preferred_language(Plug.Conn.t()) :: locale()
  defp get_preferred_language(conn) do
    header =
      conn
      |> get_req_header("accept-language")
      |> List.first()

    log(:debug, "Accept-Language header received", header: header)
    parse_accept_language_header(header)
  end


  # Parses the Accept-Language header to determine the preferred language.

  @spec parse_accept_language_header(String.t() | nil) :: locale()
  defp parse_accept_language_header(header) do
    if header in [nil, ""] do
      log(:debug, "Empty Accept-Language header, using default locale",
        default_locale: @default_locale
      )

      @default_locale
    else
      parsed_locale =
        header
        |> String.split(",")
        |> Enum.map(&String.split(&1, ";"))
        |> List.first()
        |> List.first()
        |> String.downcase()
        |> handle_language_subtags()

      log(:debug, "Parsed locale from Accept-Language header",
        parsed_locale: parsed_locale
      )

      parsed_locale
    end
  end

  # Handles language subtags, returning the primary tag if supported, or the default locale.
  @spec handle_language_subtags(String.t()) :: locale()
  defp handle_language_subtags(language_tag) do
    language_primary_tag = String.split(language_tag, "-") |> List.first()

    result =
      case language_primary_tag do
        tag when tag in @supported_locales -> tag
        _ -> @default_locale
      end

    log(:debug, "Handled language subtags", input: language_tag, result: result)
    result
  end

  # Determines the source of the chosen locale.
  @spec determine_locale_source(locale(), locale(), locale(), locale()) ::
          locale_source()
  defp determine_locale_source(
         user_locale,
         locale_from_url,
         session_locale,
         accept_language
       ) do
    source =
      cond do
        user_locale == locale_from_url -> :url
        user_locale == session_locale -> :session
        user_locale == accept_language -> :accept_language
        true -> :default
      end

    log(:debug, "Determined locale source",
      user_locale: user_locale,
      locale_from_url: locale_from_url,
      session_locale: session_locale,
      accept_language: accept_language,
      source: source
    )

    source
  end

  @spec normalize_path(path()) :: path()
  defp normalize_path(path) do
    path
    |> String.replace(~r/\/+/, "/")
    |> String.trim_trailing("/")
  end
end
