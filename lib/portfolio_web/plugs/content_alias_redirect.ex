defmodule PortfolioWeb.Plugs.ContentAliasRedirect do
  @moduledoc """
  Redirects published content aliases to their canonical URLs.
  """

  use PortfolioWeb, :verified_routes

  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn

  alias Portfolio.Content
  alias Portfolio.Content.PublicRead.Scope

  require Logger

  @content_segments %{
    "note" => "note",
    "case-study" => "case_study"
  }

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    case alias_request(conn.path_info) do
      {:ok, locale, segment, content_type, alias_url} ->
        maybe_redirect_alias(conn, locale, segment, content_type, alias_url)

      :not_content ->
        conn
    end
  end

  defp alias_request([locale, segment, alias_url])
       when is_map_key(@content_segments, segment) do
    {:ok, locale, segment, Map.fetch!(@content_segments, segment), alias_url}
  end

  defp alias_request(_path_info), do: :not_content

  defp maybe_redirect_alias(conn, locale, segment, content_type, alias_url) do
    case Content.get_alias_redirect(Scope.current(), content_type, alias_url) do
      {:ok, content} ->
        conn
        |> put_status(:moved_permanently)
        |> redirect(
          to: redirect_path(segment, locale, content.url, conn.query_string)
        )
        |> halt()

      {:error, :ambiguous_alias} ->
        Logger.warning(
          "Ambiguous content alias #{inspect(alias_url)} for #{content_type}"
        )

        conn

      {:error, :not_found} ->
        conn

      {:error, :invalid_content_type} ->
        conn
    end
  end

  defp redirect_path("note", locale, url, query_string) do
    ~p"/#{locale}/note/#{url}"
    |> with_query_string(query_string)
  end

  defp redirect_path("case-study", locale, url, query_string) do
    ~p"/#{locale}/case-study/#{url}"
    |> with_query_string(query_string)
  end

  defp with_query_string(path, ""), do: path
  defp with_query_string(path, query_string), do: path <> "?" <> query_string
end
