defmodule PortfolioWeb.Plugs.LocaleRedirection do
  @moduledoc """
  A plug that handles locale-based redirections for incoming requests.

  This plug checks the initial segment of the request path to determine if it corresponds to a supported locale.
  If the locale is not supported or missing, it redirects the user to a path that includes their preferred locale.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]
  require Logger

  @supported_locales Application.compile_env!(:portfolio, :supported_locales)
  @default_locale Application.compile_env!(:portfolio, :default_locale)
  @max_redirects 4

  @type locale :: String.t()
  @type path :: String.t()

  def init(opts), do: opts

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, _opts) do
    log(:debug, "LocaleRedirection plug called for path: #{conn.request_path}")
    log(:debug, "Request path: #{conn.request_path}")

    normalized_path = normalize_path(conn.request_path)
    log(:debug, "Normalized path: #{normalized_path}")

    {locale_from_url, remaining_path} =
      extract_locale_from_path(normalized_path)

    log(
      :debug,
      "Extracted locale: '#{locale_from_url}', Remaining path: '#{remaining_path}'"
    )

    user_locale = get_user_locale(conn)
    log(:debug, "User locale: #{user_locale}")

    conn = conn |> assign(:path_without_locale, remaining_path)

    handle_locale(conn, locale_from_url, normalized_path, user_locale)
  end

  @spec handle_locale(Plug.Conn.t(), locale(), path(), locale()) ::
          Plug.Conn.t()
  defp handle_locale(conn, locale_from_url, path, user_locale) do
    cond do
      # If the URL already contains a supported locale, no redirection is needed
      locale_from_url in @supported_locales ->
        log(:debug, "Supported locale #{locale_from_url} found in URL.")
        # Reset redirect count for supported locales
        conn |> put_session(:redirect_count, 0)

      # Check if it's a single segment path that's not a locale
      String.split(path, "/", trim: true) |> length() == 1 and
          not valid_route?(conn, path) ->
        log(:info, "Single segment invalid path detected. Halting.")

        raise Phoenix.Router.NoRouteError,
          conn: conn,
          router: PortfolioWeb.Router

      # If the locale is missing or unsupported, attempt to redirect
      true ->
        log(
          :info,
          "Unsupported or missing locale in URL, redirecting to user locale."
        )

        # Generate possible redirect paths with the user's locale
        redirect_paths = build_path_with_locale(path, user_locale)

        # Find the first valid path from the generated redirect paths
        valid_path =
          Enum.find(redirect_paths, fn path ->
            valid_route?(conn, path)
          end)

        case valid_path do
          # If no valid path is found, log a warning and return the conn without redirecting
          nil ->
            log(:warning, "No valid route found after adding locale.")

            raise Phoenix.Router.NoRouteError,
              conn: conn,
              router: PortfolioWeb.Router

          # If a valid path is found, reset the redirect count and perform the redirection
          path ->
            conn =
              conn
              |> put_session(:redirect_count, 0)

            redirect_to_locale(conn, path, user_locale)
        end
    end
  end

  @spec redirect_to_locale(Plug.Conn.t(), path(), locale()) :: Plug.Conn.t()
  defp redirect_to_locale(conn, path, _locale) do
    redirect_count = get_redirect_count(conn)
    log(:debug, "Current redirect count: #{redirect_count}")

    if redirect_count >= @max_redirects do
      log(:error, "Max redirects reached. Path: #{path}")
      conn
    else
      log(:info, "Redirecting to: #{path}")
      do_redirect(conn, path, redirect_count + 1)
    end
  end

  @spec do_redirect(Plug.Conn.t(), path(), integer()) :: Plug.Conn.t()
  defp do_redirect(conn, path, redirect_count) do
    conn
    |> put_session(:redirect_count, redirect_count)
    |> put_status(:moved_permanently)
    |> redirect(to: path)
    |> halt()
  end

  @spec valid_route?(Plug.Conn.t(), path()) :: boolean()
  defp valid_route?(conn, path) do
    log(:debug, "Checking if route is valid: #{path}")
    log(:debug, "Method: #{conn.method}, Host: #{conn.host}")

    result =
      Phoenix.Router.route_info(
        PortfolioWeb.Router,
        conn.method,
        path,
        conn.host
      ) != :error

    log(:debug, "Route #{path} is #{if result, do: "valid", else: "invalid"}")

    log(
      :debug,
      "Route info: #{inspect(Phoenix.Router.route_info(PortfolioWeb.Router, conn.method, path, conn.host))}"
    )

    result
  end

  @spec normalize_path(path()) :: path()
  def normalize_path(path) do
    path
    |> String.replace(~r/\/+/, "/")
    |> String.trim_trailing("/")
  end

  @spec extract_locale_from_path(path()) :: {locale(), path()}
  def extract_locale_from_path(path) do
    case String.split(path, "/", parts: 2, trim: true) do
      [possible_locale | remaining_parts] ->
        if String.downcase(possible_locale) in Enum.map(
             @supported_locales,
             &String.downcase/1
           ) do
          {String.downcase(possible_locale),
           "/" <> Enum.join(remaining_parts, "/")}
        else
          {"", path}
        end

      _ ->
        {"", path}
    end
  end

  @spec get_user_locale(Plug.Conn.t()) :: locale()
  defp get_user_locale(conn) do
    conn.assigns[:user_locale] ||
      get_session(conn, "user_locale") ||
      @default_locale
  end

  @spec build_path_with_locale(path(), locale()) :: [path()]
  defp build_path_with_locale(request_path, user_locale) do
    parts = String.split(request_path, "/", parts: 3, trim: true)

    locale =
      if user_locale in @supported_locales,
        do: user_locale,
        else: @default_locale

    case parts do
      [] ->
        ["/#{locale}"]

      [segment] when segment not in @supported_locales ->
        # For single-segment paths that are not locales, only try adding the locale
        ["/#{locale}/#{segment}"]

      [first | rest] when first in @supported_locales ->
        ["/#{locale}#{if rest == [], do: "", else: "/#{Enum.join(rest, "/")}"}"]

      _ ->
        [
          "/#{locale}#{if parts == [], do: "", else: "/#{Enum.join(parts, "/")}"}",
          "/#{locale}#{if tl(parts) == [], do: "", else: "/#{Enum.join(tl(parts), "/")}"}"
        ]
    end
  end

  @spec get_redirect_count(Plug.Conn.t()) :: integer()
  defp get_redirect_count(conn) do
    get_session(conn, :redirect_count) || 0
  end

  @spec log(atom(), String.t()) :: :ok
  defp log(level, message) do
    Logger.log(level, fn -> "[#{message}" end)
  end

  def supported_locales, do: @supported_locales
  def default_locale, do: @default_locale
end
