defmodule PortfolioWeb.I18nHelpers do
  @moduledoc """
  Helper functions for working with translations in tests.
  """
  import Plug.Conn

  def set_accept_language_header(conn, locale) do
    put_req_header(conn, "accept-language", locale)
  end

  def set_session_locale(conn, locale) do
    put_session(conn, "user_locale", locale)
  end

  def locale_path(path, locale) do
    "/#{locale}#{path}"
  end
end
